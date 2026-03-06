package credtemplate

import (
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/asn1"
	"encoding/base64"
	"encoding/json"

	"github.com/spiffe/spire-api-sdk/proto/spire/api/types"
)

// Unified-Identity - Verification: Hardware Integration & Delegated Certification
// OID for AttestedClaims extension: 1.3.6.1.4.1.55744.1.1 (Sovereign Unified Identity Claims)
var AttestedClaimsExtensionOID = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 55744, 1, 1}

// AttestedClaimsExtension embeds Unified Identity claims as a certificate extension.
// If unifiedJSON is provided it is embedded verbatim; otherwise the legacy
// AttestedClaims proto is marshalled to JSON.
func AttestedClaimsExtension(claims *types.AttestedClaims, unifiedJSON []byte) (pkix.Extension, error) {
	if len(unifiedJSON) > 0 {
		return pkix.Extension{
			Id:       AttestedClaimsExtensionOID,
			Value:    unifiedJSON,
			Critical: false,
		}, nil
	}

	if claims == nil {
		return pkix.Extension{}, nil
	}

	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		return pkix.Extension{}, err
	}

	return pkix.Extension{
		Id:       AttestedClaimsExtensionOID,
		Value:    claimsJSON,
		Critical: false, // Non-critical extension - allows graceful degradation
	}, nil
}

// ExtractUnifiedIdentityJSONFromCertificate returns the raw unified identity
// JSON payload stored in the certificate extension, if present.
func ExtractUnifiedIdentityJSONFromCertificate(cert *x509.Certificate) ([]byte, error) {
	if cert == nil {
		return nil, nil
	}

	for _, ext := range cert.Extensions {
		if ext.Id.Equal(AttestedClaimsExtensionOID) {
			return ext.Value, nil
		}
	}
	return nil, nil
}

// ExtractAttestedClaimsFromCertificate parses the extension and returns a
// legacy AttestedClaims proto for backwards compatibility. If the extension is
// stored using the newer Unified Identity schema, it is converted into the
// proto representation best effort.
func ExtractAttestedClaimsFromCertificate(cert *x509.Certificate) (*types.AttestedClaims, error) {
	raw, err := ExtractUnifiedIdentityJSONFromCertificate(cert)
	if err != nil || raw == nil {
		return nil, err
	}

	var claims types.AttestedClaims
	if err := json.Unmarshal(raw, &claims); err == nil {
		return &claims, nil
	}

	// Attempt to interpret Unified Identity claims schema.
	var generic map[string]any
	if err := json.Unmarshal(raw, &generic); err != nil {
		return nil, err
	}
	converted := convertUnifiedJSONToAttestedClaims(generic)
	if converted == nil {
		return nil, nil
	}
	return converted, nil
}

func convertUnifiedJSONToAttestedClaims(data map[string]any) *types.AttestedClaims {
	if data == nil {
		return nil
	}

	claims := &types.AttestedClaims{}

	if geoRaw, ok := data["grc.geolocation"]; ok {
		if geoMap, ok := geoRaw.(map[string]any); ok {
			// Build Geolocation object from map
			geo := &types.Geolocation{}
			if typeVal, ok := geoMap["type"].(string); ok {
				geo.Type = typeVal
			}
			if classIdVal, ok := geoMap["class_id"].(string); ok {
				geo.ClassId = classIdVal
			}
			if identityHashVal, ok := geoMap["identity_hash"].(string); ok {
				geo.IdentityHash = identityHashVal
			}
			if providerVal, ok := geoMap["provider"].(string); ok {
				geo.Provider = providerVal
			}
			if geo.Type != "" || geo.ClassId != "" {
				claims.Geolocation = geo
			}
		}
	}

	// Gen 4: Extract MNO Endorsement if present
	if mnoRaw, ok := data["grc.mno_endorsement"]; ok {
		if mnoMap, ok := mnoRaw.(map[string]any); ok {
			mno := &types.MNOEndorsement{}
			if verified, ok := mnoMap["verified"].(bool); ok {
				mno.Verified = verified
			}
			if signature, ok := mnoMap["signature"].(string); ok {
				mno.Signature = signature
			}
			if keyId, ok := mnoMap["key_id"].(string); ok {
				mno.KeyId = keyId
			}
			if dataB64, ok := mnoMap["data_b64"].(string); ok {
				if decoded, err := base64.StdEncoding.DecodeString(dataB64); err == nil {
					mno.EndorsementJson = string(decoded)
				}
			}
			claims.MnoEndorsement = mno
		}
	}

	// Gen 4: Extract Sovereignty Receipt (ZKP Proof) or Commitments
	if receiptRaw, ok := data["grc.sovereignty_receipt"]; ok {
		if receiptMap, ok := receiptRaw.(map[string]any); ok {
			if hashVal, ok := receiptMap["hash"].(string); ok {
				claims.SovereigntyReceiptHash = hashVal
			}
			if uriVal, ok := receiptMap["uri"].(string); ok {
				claims.SovereigntyReceiptUri = uriVal
			}
			if proofB64, ok := receiptMap["proof_b64"].(string); ok {
				claims.SovereigntyReceipt = proofB64
			}
		}
	}

	return claims
}
