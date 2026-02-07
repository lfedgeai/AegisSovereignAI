package unifiedidentity

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/spiffe/spire-api-sdk/proto/spire/api/types"
)

const (
	KeySourceTPMApp   = "tpm-app-key"
	KeySourceWorkload = "workload-key"
)

// BuildClaimsJSON constructs the grc.* Unified Identity claims blob described in
// docs/federated-jwt.md. The resulting JSON can be embedded directly into the
// SVID extension or other federated artifacts.
func BuildClaimsJSON(spiffeID, keySource, workloadPublicKeyPEM string, sovereignAttestation *types.SovereignAttestation, attestedClaims *types.AttestedClaims) ([]byte, error) {
	if keySource != KeySourceTPMApp && keySource != KeySourceWorkload {
		return nil, fmt.Errorf("unifiedidentity: unsupported key source %q", keySource)
	}

	claims := make(map[string]any)

	workload := map[string]any{
		"workload-id": spiffeID,
		"key-source":  keySource,
	}
	if keySource == KeySourceWorkload && workloadPublicKeyPEM != "" {
		workload["public-key"] = workloadPublicKeyPEM
	}
	if sovereignAttestation != nil && sovereignAttestation.WorkloadCodeHash != "" {
		workload["workload-code-hash"] = sovereignAttestation.WorkloadCodeHash
	}
	claims["grc.workload"] = workload

	// Unified-Identity - Verification: TPM attestation and geolocation are ONLY for agent SVIDs
	// Workload SVIDs should NOT include TPM attestation or geolocation - those are covered by the SPIRE agent
	// Only include TPM attestation and geolocation for agent SVIDs (KeySourceTPMApp)
	if keySource == KeySourceTPMApp {
		tpm := map[string]any{}
		if sovereignAttestation != nil {
			if sovereignAttestation.AppKeyPublic != "" {
				tpm["app-key-public"] = sovereignAttestation.AppKeyPublic
			}
			if len(sovereignAttestation.AppKeyCertificate) > 0 {
				tpm["app-key-certificate"] = base64.StdEncoding.EncodeToString(sovereignAttestation.AppKeyCertificate)
			}
			if sovereignAttestation.TpmSignedAttestation != "" {
				tpm["quote"] = sovereignAttestation.TpmSignedAttestation
			}
			if sovereignAttestation.ChallengeNonce != "" {
				tpm["challenge-nonce"] = sovereignAttestation.ChallengeNonce
			}
		}

		// Unified-Identity - Verification: Hardware Integration & Delegated Certification
		// Structured claims for Sensor Type Isolation (Task 12b)
		if attestedClaims != nil && attestedClaims.Geolocation != nil {
			geo := attestedClaims.Geolocation
			pcrIndex := 15
			if pcrStr := os.Getenv("UNIFIED_IDENTITY_PCR_INDEX"); pcrStr != "" {
				if parsed, err := strconv.Atoi(pcrStr); err == nil {
					pcrIndex = parsed
				}
			}
			geoObj := map[string]any{
				"tpm-attested-location":  true,
				"tpm-attested-pcr-index": pcrIndex,
			}

			// Gen 4: Add ZKP sovereignty receipt if present
			if attestedClaims.SovereigntyReceipt != "" {
				geoObj["sovereignty_receipt"] = attestedClaims.SovereigntyReceipt
			}

			// Gen 4: Add MNO endorsement if present
			if attestedClaims.MnoEndorsement != nil {
				mnoObj := map[string]any{
					"verified": attestedClaims.MnoEndorsement.Verified,
				}
				if attestedClaims.MnoEndorsement.EndorsementJson != "" {
					mnoObj["endorsement_json"] = attestedClaims.MnoEndorsement.EndorsementJson
				}
				if attestedClaims.MnoEndorsement.Signature != "" {
					mnoObj["signature"] = attestedClaims.MnoEndorsement.Signature
				}
				if attestedClaims.MnoEndorsement.KeyId != "" {
					mnoObj["key_id"] = attestedClaims.MnoEndorsement.KeyId
				}
				geoObj["mno_endorsement"] = mnoObj
			}

			// 1. Mobile-Specific Claims (Nested)
			if geo.Type == "mobile" {
				mobileObj := map[string]any{}
				if geo.SensorId != "" {
					mobileObj["sensor_id"] = geo.SensorId
				}
				if geo.SensorImei != "" {
					mobileObj["sensor_imei"] = geo.SensorImei
				}
				if geo.SensorImsi != "" {
					mobileObj["sim_imsi"] = geo.SensorImsi
				}
				if geo.SensorMsisdn != "" {
					mobileObj["sim_msisdn"] = geo.SensorMsisdn
				}
				locationVerif := map[string]any{}
				if geo.Latitude != 0 {
					locationVerif["latitude"] = geo.Latitude
				}
				if geo.Longitude != 0 {
					locationVerif["longitude"] = geo.Longitude
				}
				if geo.Accuracy != 0 {
					locationVerif["accuracy"] = geo.Accuracy
				}
				if len(locationVerif) > 0 {
					mobileObj["location_verification"] = locationVerif
				}
				geoObj["mobile"] = mobileObj
			}

			// 2. GNSS-Specific Claims (Nested)
			if geo.Type == "gnss" {
				gnssObj := map[string]any{}
				if geo.SensorId != "" {
					gnssObj["sensor_id"] = geo.SensorId
				}
				if geo.SensorSerialNumber != "" {
					gnssObj["sensor_serial_number"] = geo.SensorSerialNumber
				}
				retrievedLoc := map[string]any{}
				if geo.Latitude != 0 {
					retrievedLoc["latitude"] = geo.Latitude
				}
				if geo.Longitude != 0 {
					retrievedLoc["longitude"] = geo.Longitude
				}
				if geo.Accuracy != 0 {
					retrievedLoc["accuracy"] = geo.Accuracy
				}
				if len(retrievedLoc) > 0 {
					gnssObj["retrieved_location"] = retrievedLoc
				}
				geoObj["gnss"] = gnssObj
			}

			// Add sensor signature (required field in proto)
			if geo.SensorSignature != "" {
				geoObj["sensor_signature"] = geo.SensorSignature
			}

			claims["grc.geolocation"] = geoObj
		}

		if len(tpm) > 0 {
			claims["grc.tpm-attestation"] = tpm
		}
	}
	// For KeySourceWorkload: Only include grc.workload (no TPM attestation, no geolocation)

	return json.Marshal(claims)
}

// Unified-Identity - Verification: Hardware Integration & Delegated Certification
// buildGeolocationClaim structures geolocation data according to federated-jwt.md schema
// Input format: "country:state:city:latitude:longitude" or "country: description"
// If TPM-attested (hasSovereignAttestation=true), sets tpm-attested-location and tpm-attested-pcr-index
func buildGeolocationClaim(geoStr string, hasSovereignAttestation bool) map[string]any {
	geo := make(map[string]any)

	// Parse geolocation string
	// Format 1: "country:state:city:latitude:longitude" (precise coordinates)
	// Format 2: "country: description" (administrative only)
	parts := strings.Split(geoStr, ":")

	if len(parts) >= 5 {
		// Format 1: Has coordinates - use precise format
		country := strings.TrimSpace(parts[0])
		state := strings.TrimSpace(parts[1])
		city := strings.TrimSpace(parts[2])
		latStr := strings.TrimSpace(parts[3])
		lonStr := strings.TrimSpace(parts[4])

		lat, errLat := strconv.ParseFloat(latStr, 64)
		lon, errLon := strconv.ParseFloat(lonStr, 64)

		if errLat == nil && errLon == nil {
			// Use precise format with coordinates
			geo["physical-location"] = map[string]any{
				"format": "precise",
				"precise": map[string]any{
					"latitude":  lat,
					"longitude": lon,
				},
			}

			// Add administrative boundaries if available
			if country != "" {
				jurisdiction := map[string]any{
					"country": country,
				}
				if state != "" {
					jurisdiction["state"] = state
				}
				if city != "" {
					jurisdiction["city"] = city
				}
				geo["jurisdiction"] = jurisdiction
			}
		} else {
			// Fall back to administrative format
			geo["physical-location"] = map[string]any{
				"format": "administrative",
				"administrative": map[string]any{
					"country": country,
					"state":   state,
					"city":    city,
				},
			}
		}
	} else if len(parts) >= 1 {
		// Format 2: Administrative only
		country := strings.TrimSpace(parts[0])
		state := ""
		city := ""
		if len(parts) >= 2 {
			state = strings.TrimSpace(parts[1])
		}
		if len(parts) >= 3 {
			city = strings.TrimSpace(parts[2])
		}

		admin := map[string]any{
			"country": country,
		}
		if state != "" {
			admin["state"] = state
		}
		if city != "" {
			admin["city"] = city
		}

		geo["physical-location"] = map[string]any{
			"format":         "administrative",
			"administrative": admin,
		}

		jurisdiction := map[string]any{
			"country": country,
		}
		if state != "" {
			jurisdiction["state"] = state
		}
		if city != "" {
			jurisdiction["city"] = city
		}
		geo["jurisdiction"] = jurisdiction
	} else {
		// Invalid format, return nil
		return nil
	}

	// Unified-Identity - Verification: Hardware Integration & Delegated Certification
	// If TPM attestation is present, mark geolocation as TPM-attested
	if hasSovereignAttestation {
		geo["tpm-attested-location"] = true
		geo["tpm-attested-pcr-index"] = 15 // PCR 15 is used for geolocation per rust-keylime agent
	}

	return geo
}
