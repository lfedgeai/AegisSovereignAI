package unifiedidentity

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"

	"github.com/spiffe/spire-api-sdk/proto/spire/api/types"
)

const (
	KeySourceTPMApp   = "tpm-app-key"
	KeySourceWorkload = "workload-key"
)

// BuildLAHBundle constructs the lah-bundle SVID extended claims JSON.
// This replaces the legacy grc.* flat namespace with the privacy-preserving
// nested structure defined in docs/lah-bundle-spec.md.
//
// All geolocation-sensitive data (coordinates, IMEI, IMSI, serial numbers)
// is represented as cryptographic hashes only — never in plaintext.
//
// The lah_bundle proto carries the pre-computed fields from the Keylime verifier:
//   - tpm_ak:                  AK public key (Base64URL)
//   - geolocation_id_hash:     SHA-256(tpm-ak || sensor-unique-id)
//   - geolocation_proof_hash:  SHA-256(JCS(geolocation_payload)) or SHA-256(zkp-proof-bytes)
//   - privacy_technique:       0=None, 1=ZKP
//   - geolocation_payload:     JSON-encoded RawGeolocation or ZkpGeolocation
//   - nonce:                   chained freshness nonce from management plane
//   - timestamp:               Unix epoch seconds
//   - tpm_quote_seal:          TPM2_Quote over qualifying data (Base64URL)
//
// mno_endorsement (optional) provides carrier co-attestation over geolocation_payload only.
func BuildLAHBundle(spiffeID, keySource string, lahBundle *types.LAHBundle, mnoEndorsement *types.LAHMNOEndorsement) ([]byte, error) {
	if keySource != KeySourceTPMApp && keySource != KeySourceWorkload {
		return nil, fmt.Errorf("unifiedidentity: unsupported key source %q", keySource)
	}

	// Workload identity wrapper — always present
	claims := map[string]any{
		"workload": map[string]any{
			"workload-id": spiffeID,
			"key-source":  keySource,
		},
	}

	if lahBundle == nil {
		// No location evidence available — emit workload identity only
		return json.Marshal(claims)
	}

	// Build geolocation-payload inner object from proto bytes
	var geoPayload any
	if len(lahBundle.GeolocationPayload) > 0 {
		if err := json.Unmarshal(lahBundle.GeolocationPayload, &geoPayload); err != nil {
			return nil, fmt.Errorf("unifiedidentity: failed to unmarshal geolocation_payload: %w", err)
		}
	}

	// Build the lah-bundle object
	lahObj := map[string]any{
		// Hardware identity anchor — the TPM AK that produced the tpm_quote_seal.
		// The TPM enforces co-residency: only this key can produce the Quote.
		"tpm-ak": lahBundle.TpmAk,

		// Sensor binding hash — opaque to verifier.
		// Mobile: SHA-256(tpm-ak || IMEI || IMSI)
		// GNSS:   SHA-256(tpm-ak || serial || class-id)
		// Device identity privacy (IMEI/IMSI/serial) is protected regardless of privacy-technique.
		"geolocation-id-hash": lahBundle.GeolocationIdHash,

		// SHA-256 commitment over geolocation-payload.
		// Required in BOTH privacy modes:
		//   privacy-technique=1: the only location data in the bundle (ZKP commitment).
		//   privacy-technique=0: TPM qualifying data is 32 bytes — hash provides uniform
		//                        tpm-quote-seal structure across both modes.
		"geolocation-proof-hash": lahBundle.GeolocationProofHash,

		// Location privacy mode: "zkp" or "none".
		//   "none": geolocation-payload contains raw lat/lon/accuracy.
		//   "zkp":  geolocation-payload contains zkp-proof-uri only.
		"privacy-technique": lahBundle.PrivacyTechnique,

		// Inner location data. Structure depends on privacy-technique.
		// Both geolocation-proof-hash and mno-sig (if present) commit to this object.
		"geolocation-payload": geoPayload,

		// Chained freshness nonce from the management plane.
		// HMAC(secret, n || chain[n-1]) — enables the management plane to detect
		// skipped/reordered attestations via a Merkle chain mirroring TPM PCR extension.
		"nonce": lahBundle.Nonce,

		// Unix epoch seconds — set by the LAH agent at bundle construction time.
		"timestamp": lahBundle.Timestamp,

		// TPM2_Quote by the AK in tpm-ak. Qualifying data =
		// SHA-256(JCS({tpm-ak, geolocation-id-hash, geolocation-proof-hash,
		//              privacy-technique, nonce, timestamp})).
		// geolocation-payload and mno-endorsement are bound INDIRECTLY via geolocation-proof-hash.
		"tpm-quote-seal": lahBundle.TpmQuoteSeal,
	}

	// Workload Identity Agent image digest — detects SPIRE agent binary compromise.
	if lahBundle.WorkloadIdentityAgentImageDigest != "" {
		lahObj["workload-identity-agent-image-digest"] = lahBundle.WorkloadIdentityAgentImageDigest
	}

	claims["lah-bundle"] = lahObj

	// MNO endorsement: optional carrier co-attestation over geolocation-payload ONLY.
	// The MNO attests location data within carrier visibility — it does NOT sign
	// host-level fields (tpm-ak, nonce, tpm-quote-seal).
	if mnoEndorsement != nil && mnoEndorsement.MnoSig != "" {
		claims["mno-endorsement"] = map[string]any{
			"mno-key-cert": mnoEndorsement.MnoKeyCert,
			"mno-sig":      mnoEndorsement.MnoSig,
		}
	}

	return json.Marshal(claims)
}

// GeolocationIDHash computes the sensor-binding hash for inclusion in LAHBundle.
// This is the agent-side computation — transparent to the verifier.
//
// Mobile: SHA-256(tpmAKBytes || imeiBytes || imsiBytes)
// GNSS:   SHA-256(tpmAKBytes || serialBytes || classIDBytes)
//
// tpmAKRaw should be the raw DER/PEM bytes of the AK public key (same as tpm-ak field).
func GeolocationIDHash(tpmAKRaw []byte, sensorUniqueComponents ...[]byte) string {
	h := sha256.New()
	h.Write(tpmAKRaw)
	for _, component := range sensorUniqueComponents {
		h.Write(component)
	}
	return base64.URLEncoding.EncodeToString(h.Sum(nil))
}

// BuildLAHBundleFromKeylimeClaims is a convenience constructor that builds a
// *types.LAHBundle from the raw fields returned by the Keylime verifier.
// The tpm_quote_seal, nonce, and timestamp must be populated by the calling server
// from the SovereignAttestation / attestation context.
func BuildLAHBundleFromKeylimeClaims(
	tpmAK string,
	geolocationIDHash string,
	privacyTechnique string,
	geolocationPayload []byte,
	tpmQuoteSeal string,
	nonce string,
	timestamp int64,
	agentImageDigest string,
) (*types.LAHBundle, error) {
	// Compute geolocation-proof-hash over the geolocation-payload bytes
	// (for privacy-technique="none": SHA-256(JCS({lat,lon,accuracy})))
	// (for privacy-technique="zkp": passed in as-is from verifier — SHA-256(zkp-proof-bytes))
	proofHash := sha256.Sum256(geolocationPayload)
	proofHashB64 := base64.URLEncoding.EncodeToString(proofHash[:])

	return &types.LAHBundle{
		TpmAk:                            tpmAK,
		GeolocationIdHash:                geolocationIDHash,
		GeolocationProofHash:             proofHashB64,
		PrivacyTechnique:                 privacyTechnique,
		GeolocationPayload:               geolocationPayload,
		Nonce:                            nonce,
		Timestamp:                        timestamp,
		TpmQuoteSeal:                     tpmQuoteSeal,
		WorkloadIdentityAgentImageDigest: agentImageDigest,
	}, nil
}
