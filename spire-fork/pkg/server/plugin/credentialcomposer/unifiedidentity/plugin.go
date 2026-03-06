package unifiedidentity

import (
	"context"
	"crypto/x509/pkix"
	"encoding/asn1"
	"encoding/json"
	"sync"
	"time"

	"github.com/hashicorp/hcl"
	"github.com/sirupsen/logrus"
	"github.com/spiffe/spire-api-sdk/proto/spire/api/types"
	credentialcomposerv1 "github.com/spiffe/spire-plugin-sdk/proto/spire/plugin/server/credentialcomposer/v1"
	configv1 "github.com/spiffe/spire-plugin-sdk/proto/spire/service/common/config/v1"
	"github.com/spiffe/spire/pkg/common/catalog"
	"github.com/spiffe/spire/pkg/common/pluginconf"
	"github.com/spiffe/spire/pkg/server/keylime"
	"github.com/spiffe/spire/pkg/server/policy"
	"github.com/spiffe/spire/pkg/server/unifiedidentity"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func BuiltIn() catalog.BuiltIn {
	return builtIn(New())
}

func builtIn(p *Plugin) catalog.BuiltIn {
	return catalog.MakeBuiltIn("unifiedidentity",
		credentialcomposerv1.CredentialComposerPluginServer(p),
		configv1.ConfigServiceServer(p),
	)
}

type Configuration struct {
	KeylimeURL          string   `hcl:"keylime_url"`
	TLSCert             string   `hcl:"tls_cert"`
	TLSKey              string   `hcl:"tls_key"`
	CACert              string   `hcl:"ca_cert"`
	ServerName          string   `hcl:"server_name"`
	AllowedGeolocations []string `hcl:"allowed_geolocations"`
}

func buildConfig(coreConfig catalog.CoreConfig, hclText string, status *pluginconf.Status) *Configuration {
	newConfig := new(Configuration)
	if err := hcl.Decode(newConfig, hclText); err != nil {
		status.ReportError("plugin configuration is malformed")
		return nil
	}
	return newConfig
}

type Plugin struct {
	credentialcomposerv1.UnsafeCredentialComposerServer
	configv1.UnsafeConfigServer

	mu            sync.RWMutex
	keylimeClient *keylime.Client
	policyEngine  *policy.Engine

	// LAH-Bundle: Cache verified location evidence for workload inheritance
	// Key: Agent SPIFFE ID (keylime_agent_uuid)
	lahBundleCache  map[string]*types.LAHBundle
	mnoCache        map[string]*types.LAHMNOEndorsement
	latestLAHBundle *types.LAHBundle
	latestMNO       *types.LAHMNOEndorsement
}

func New() *Plugin {
	return &Plugin{
		lahBundleCache: make(map[string]*types.LAHBundle),
		mnoCache:       make(map[string]*types.LAHMNOEndorsement),
	}
}

func (p *Plugin) ComposeServerX509CA(context.Context, *credentialcomposerv1.ComposeServerX509CARequest) (*credentialcomposerv1.ComposeServerX509CAResponse, error) {
	return nil, status.Error(codes.Unimplemented, "not implemented")
}

func (p *Plugin) ComposeServerX509SVID(context.Context, *credentialcomposerv1.ComposeServerX509SVIDRequest) (*credentialcomposerv1.ComposeServerX509SVIDResponse, error) {
	return nil, status.Error(codes.Unimplemented, "not implemented")
}

func (p *Plugin) Configure(ctx context.Context, req *configv1.ConfigureRequest) (*configv1.ConfigureResponse, error) {
	newConfig, _, err := pluginconf.Build(req, buildConfig)
	if err != nil {
		return nil, err
	}

	p.mu.Lock()
	defer p.mu.Unlock()

	if newConfig.KeylimeURL != "" {
		client, err := keylime.NewClient(keylime.Config{
			BaseURL:    newConfig.KeylimeURL,
			TLSCert:    newConfig.TLSCert,
			TLSKey:     newConfig.TLSKey,
			CACert:     newConfig.CACert,
			ServerName: newConfig.ServerName,
			Logger:     logrus.New(), // The client will wrap this with its own logger if needed
		})
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to create Keylime client: %v", err)
		}
		p.keylimeClient = client
	}

	p.policyEngine = policy.NewEngine(policy.PolicyConfig{
		AllowedGeolocations: newConfig.AllowedGeolocations,
	})

	return &configv1.ConfigureResponse{}, nil
}

func (p *Plugin) Validate(ctx context.Context, req *configv1.ValidateRequest) (*configv1.ValidateResponse, error) {
	_, notes, err := pluginconf.Build(req, buildConfig)

	return &configv1.ValidateResponse{
		Valid: err == nil,
		Notes: notes,
	}, err
}

func (p *Plugin) ComposeAgentX509SVID(ctx context.Context, req *credentialcomposerv1.ComposeAgentX509SVIDRequest) (*credentialcomposerv1.ComposeAgentX509SVIDResponse, error) {
	if req.Attributes == nil {
		return nil, status.Error(codes.InvalidArgument, "request missing attributes")
	}

	attributes := req.Attributes
	// Debug logging
	logrus.Infof("Unified-Identity: ComposeAgentX509SVID called for %s", req.SpiffeId)

	lahBundle, unifiedJSON, err := p.processSovereignAttestation(ctx, req.SpiffeId, req.PublicKey, unifiedidentity.KeySourceTPMApp, true)
	if err != nil {
		logrus.Errorf("Unified-Identity: processSovereignAttestation failed: %v", err)
		return nil, err
	}

	if lahBundle != nil || len(unifiedJSON) > 0 {
		ext, err := attestedClaimsExtension(lahBundle, unifiedJSON)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to create LAH-Bundle extension: %v", err)
		}
		if ext.Id != nil {
			attributes.ExtraExtensions = append(attributes.ExtraExtensions, &credentialcomposerv1.X509Extension{
				Oid:      ext.Id.String(),
				Value:    ext.Value,
				Critical: ext.Critical,
			})
		}
	}

	return &credentialcomposerv1.ComposeAgentX509SVIDResponse{
		Attributes: attributes,
	}, nil
}

func (p *Plugin) ComposeWorkloadX509SVID(ctx context.Context, req *credentialcomposerv1.ComposeWorkloadX509SVIDRequest) (*credentialcomposerv1.ComposeWorkloadX509SVIDResponse, error) {
	if req.Attributes == nil {
		return nil, status.Error(codes.InvalidArgument, "request missing attributes")
	}

	attributes := req.Attributes
	lahBundle, unifiedJSON, err := p.processSovereignAttestation(ctx, req.SpiffeId, req.PublicKey, unifiedidentity.KeySourceWorkload, false)
	_ = lahBundle // workload SVIDs use unifiedJSON only
	if err != nil {
		return nil, err
	}

	if len(unifiedJSON) > 0 {
		ext, err := attestedClaimsExtension(nil, unifiedJSON)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to create LAH-Bundle extension: %v", err)
		}
		if ext.Id != nil {
			attributes.ExtraExtensions = append(attributes.ExtraExtensions, &credentialcomposerv1.X509Extension{
				Oid:      ext.Id.String(),
				Value:    ext.Value,
				Critical: ext.Critical,
			})
		}
	}

	return &credentialcomposerv1.ComposeWorkloadX509SVIDResponse{
		Attributes: attributes,
	}, nil
}

func (p *Plugin) processSovereignAttestation(ctx context.Context, spiffeID string, publicKey []byte, keySource string, isAgent bool) (*types.LAHBundle, []byte, error) {
	sa := unifiedidentity.FromSovereignAttestation(ctx)
	if sa == nil {
		if !isAgent {
			// Normal for workloads: no SA in context — fall through to cache lookup below
			logrus.Infof("Unified-Identity: SovereignAttestation is nil for workload %s — will inherit from agent cache", spiffeID)
		} else {
			// Agent with no SA: emit workload identity only (Keylime not configured)
			logrus.Infof("Unified-Identity: SovereignAttestation is nil for agent %s (no location evidence)", spiffeID)
			unifiedJSON, err := unifiedidentity.BuildLAHBundle(spiffeID, keySource, nil, nil)
			return nil, unifiedJSON, err
		}
	}
	if sa != nil {
		logrus.Infof("Unified-Identity: SovereignAttestation found in context for %s", spiffeID)
		logrus.Infof("Unified-Identity: SA Details: TpmAttestation len=%d, AppKeyCert len=%d", len(sa.TpmSignedAttestation), len(sa.AppKeyCertificate))
	}

	p.mu.RLock()
	client := p.keylimeClient
	engine := p.policyEngine
	p.mu.RUnlock()

	// Workload SVIDs inherit LAH-Bundle from the agent SVID (node attestation results)
	if !isAgent {
		nodeID := ""
		if sa != nil {
			nodeID = sa.KeylimeAgentUuid
		}
		p.mu.RLock()
		cachedBundle, ok := p.lahBundleCache[nodeID]
		cachedMNO := p.mnoCache[nodeID]
		if !ok && p.latestLAHBundle != nil {
			// Fallback to latest verified bundle for POC (single node environment)
			cachedBundle = p.latestLAHBundle
			cachedMNO = p.latestMNO
			ok = true
		}
		p.mu.RUnlock()

		if ok {
			logrus.Infof("Unified-Identity: Inheriting LAH-Bundle for workload %s from cache (node=%s)", spiffeID, nodeID)
			unifiedJSON, err := unifiedidentity.BuildLAHBundle(spiffeID, keySource, cachedBundle, cachedMNO)
			return cachedBundle, unifiedJSON, err
		}
		logrus.Infof("Unified-Identity: No cached LAH-Bundle for node %s - workload SVID will have workload identity only", nodeID)
		unifiedJSON, err := unifiedidentity.BuildLAHBundle(spiffeID, keySource, nil, nil)
		return nil, unifiedJSON, err
	}

	if client == nil {
		logrus.Infof("Unified-Identity: Keylime Client is nil - skipping verification")
		return nil, nil, nil
	}
	logrus.Infof("Unified-Identity: Proceeding to verify evidence with Keylime for agent SVID")

	// Debug: Inspect SovereignAttestation fields
	logrus.Infof("Unified-Identity: Debug Payload - Quote Length: %d", len(sa.TpmSignedAttestation))
	if len(sa.TpmSignedAttestation) > 50 {
		logrus.Infof("Unified-Identity: Debug Payload - Quote Preview: %s...", sa.TpmSignedAttestation[:50])
	} else {
		logrus.Infof("Unified-Identity: Debug Payload - Quote Full: %s", sa.TpmSignedAttestation)
	}
	logrus.Infof("Unified-Identity: Debug Payload - AppKeyPublic Length: %d", len(sa.AppKeyPublic))
	logrus.Infof("Unified-Identity: Debug Payload - AppKeyCertificate Length: %d", len(sa.AppKeyCertificate))
	logrus.Infof("Unified-Identity: Debug Payload - ChallengeNonce: %s", sa.ChallengeNonce)
	logrus.Infof("Unified-Identity: Debug Payload - WorkloadCodeHash: %s", sa.WorkloadCodeHash)

	// Build Keylime request
	keylimeReq, err := keylime.BuildVerifyEvidenceRequest(&keylime.SovereignAttestationProto{
		TpmSignedAttestation: sa.TpmSignedAttestation,
		AppKeyPublic:         sa.AppKeyPublic,
		AppKeyCertificate:    sa.AppKeyCertificate,
		ChallengeNonce:       sa.ChallengeNonce,
		WorkloadCodeHash:     sa.WorkloadCodeHash,
		KeylimeAgentUuid:     sa.KeylimeAgentUuid,
	}, "")
	if err != nil {
		return nil, nil, status.Errorf(codes.Internal, "failed to build Keylime request: %v", err)
	}

	// Call Keylime Verifier
	keylimeClaims, err := client.VerifyEvidence(keylimeReq)
	if err != nil {
		return nil, nil, status.Errorf(codes.PermissionDenied, "keylime verification failed: %v", err)
	}

	// Evaluate policy
	if engine != nil {

		policyClaims := policy.ConvertKeylimeAttestedClaims(&policy.KeylimeAttestedClaims{
			GeolocationType:        keylimeClaims.Geolocation.Type,
			ClassID:                keylimeClaims.Geolocation.SensorID,
			IdentityHash:           keylimeClaims.Geolocation.IdentityHash,
			SovereigntyReceiptHash: keylimeClaims.SovereigntyReceiptHash,
			SovereigntyReceiptURI:  keylimeClaims.SovereigntyReceiptUri,
		})

		policyResult, err := engine.Evaluate(policyClaims)
		if err != nil {
			return nil, nil, status.Errorf(codes.Internal, "policy evaluation failed: %v", err)
		}

		if !policyResult.Allowed {
			return nil, nil, status.Errorf(codes.PermissionDenied, "policy evaluation failed: %s", policyResult.Reason)
		}
	}

	// Build the geolocation-payload inner JSON
	// privacy-technique="zkp" (ZKP): {zkp-proof-uri} only — scheme is implicit in the deployed system
	// privacy-technique="none" (Raw): use Geolocation.Value for lat/lon string or just record sensor type
	var privacyTechnique string
	var geoPayloadBytes []byte
	if keylimeClaims.SovereigntyReceiptHash != "" {
		// ZKP commitment-verification mode
		privacyTechnique = "zkp"
		geoPayload := map[string]any{
			"zkp-proof-uri": keylimeClaims.SovereigntyReceiptUri,
		}
		geoPayloadBytes, _ = json.Marshal(geoPayload)
	} else {
		// Raw mode — embed what Keylime returned
		privacyTechnique = "none"
		geoValue := ""
		if keylimeClaims.Geolocation != nil {
			geoValue = keylimeClaims.Geolocation.Value
		}
		geoPayload := map[string]any{
			"value": geoValue, // raw location string from sensor
		}
		geoPayloadBytes, _ = json.Marshal(geoPayload)
	}

	// Compute geolocation-id-hash: SHA-256(tpm-ak || sensor-unique-id)
	// Sensor-unique-id = SensorID (class_id from keylime), which encodes IMEI/IMSI or serial
	sensorUniqueID := ""
	if keylimeClaims.Geolocation != nil {
		sensorUniqueID = keylimeClaims.Geolocation.SensorID
	}
	geoIDHash := unifiedidentity.GeolocationIDHash(
		[]byte(sa.AppKeyPublic),
		[]byte(sensorUniqueID),
	)

	// Build LAHBundle proto
	// tpm_quote_seal: prefer the Keylime-verified quote (piped via attested_claims)
	// over sa.TpmSignedAttestation (empty — agent doesn't carry the quote itself).
	tpmQuoteSeal := sa.TpmSignedAttestation
	if keylimeClaims.TpmQuoteSeal != "" {
		tpmQuoteSeal = keylimeClaims.TpmQuoteSeal
		logrus.Infof("Unified-Identity: Using Keylime-verified TPM quote seal (len=%d)", len(tpmQuoteSeal))
	}
	lahBundle, err := unifiedidentity.BuildLAHBundleFromKeylimeClaims(
		sa.AppKeyPublic,
		geoIDHash,
		privacyTechnique,
		geoPayloadBytes,
		tpmQuoteSeal,      // tpm_quote_seal (from Keylime verifier)
		sa.ChallengeNonce, // nonce (chained, issued by management plane)
		time.Now().Unix(),
		keylimeClaims.AgentImageDigest,
	)
	if err != nil {
		return nil, nil, status.Errorf(codes.Internal, "failed to build LAH bundle: %v", err)
	}

	// Build MNO endorsement if carrier co-attestation is present
	// mno-sig = MNOEndorsement.Signature; mno-key-cert = KeyID (cert not returned by Keylime client)
	var protoMNO *types.LAHMNOEndorsement
	if keylimeClaims.MNOEndorsement != nil && keylimeClaims.MNOEndorsement.Signature != "" {
		protoMNO = &types.LAHMNOEndorsement{
			MnoKeyCert: keylimeClaims.MNOEndorsement.KeyID, // KeyID as cert reference
			MnoSig:     keylimeClaims.MNOEndorsement.Signature,
		}
	}

	logrus.Infof("Unified-Identity: Built LAH-Bundle (pt=%d, geo-id-hash=%s, proof-hash=%s)",
		privacyTechnique, geoIDHash, lahBundle.GeolocationProofHash)

	unifiedJSON, err := unifiedidentity.BuildLAHBundle(spiffeID, keySource, lahBundle, protoMNO)
	if err != nil {
		return nil, nil, status.Errorf(codes.Internal, "failed to build LAH bundle JSON: %v", err)
	}

	// Cache LAH-Bundle for workloads on this node
	p.mu.Lock()
	if sa != nil && sa.KeylimeAgentUuid != "" {
		p.lahBundleCache[sa.KeylimeAgentUuid] = lahBundle
		p.mnoCache[sa.KeylimeAgentUuid] = protoMNO
	}
	p.latestLAHBundle = lahBundle
	p.latestMNO = protoMNO
	p.mu.Unlock()

	return lahBundle, unifiedJSON, nil
}

// attestedClaimsOID is the OID for the AegisSovereignAI attested claims X.509 extension.
// Arc: 1.3.6.1.4.1 (private enterprise), 55744 (Sovereign Unified Identity Claims).
// This is the canonical OID from the Aegis SPIRE fork (credtemplate/attested_claims_extension.go)
// that passed all integration tests. Must match the OID checked by dump-svid-attested-claims.sh.
var attestedClaimsOID = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 55744, 1, 1}

// attestedClaimsExtension encodes LAH-Bundle unified identity data as a pkix.Extension.
// The extension value is the raw unifiedJSON bytes (JSON-encoded lah-bundle claims).
func attestedClaimsExtension(_ any, unifiedJSON []byte) (pkix.Extension, error) {
	if len(unifiedJSON) == 0 {
		// Return a zero-value extension; callers check ext.Id != nil before appending.
		return pkix.Extension{}, nil
	}
	return pkix.Extension{
		Id:       attestedClaimsOID,
		Critical: false,
		Value:    unifiedJSON,
	}, nil
}

func (p *Plugin) ComposeWorkloadJWTSVID(context.Context, *credentialcomposerv1.ComposeWorkloadJWTSVIDRequest) (*credentialcomposerv1.ComposeWorkloadJWTSVIDResponse, error) {
	return nil, status.Error(codes.Unimplemented, "not implemented")
}
