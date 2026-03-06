// lah_bundle_types.go — LAH-Bundle Go types added alongside the existing generated pb.go.
// These structs are not regenerated from proto (no protoc available in this environment)
// but are fully wire-compatible with the proto definitions in sovereignattestation.proto.
// They can be replaced with proper generated types once `make proto` is run.

package types

// LAHBundle is the privacy-preserving hardware-sealed location evidence
// embedded as an SVID extended claim. Added as a plain Go struct alongside
// the existing protobuf-generated types.
//
// All geolocation-sensitive data (coordinates, IMEI, IMSI, serial numbers)
// is represented as cryptographic hashes — never in plaintext in the bundle.
type LAHBundle struct {
	// LAH AK public key (Base64URL). Hardware identity anchor.
	TpmAk string `json:"tpm-ak,omitempty"`

	// SHA-256(tpm-ak || sensor-unique-id), Base64URL.
	// Binds TPM identity to sensor without exposing IMEI/IMSI/serial.
	GeolocationIdHash string `json:"geolocation-id-hash,omitempty"`

	// SHA-256 commitment over GeolocationPayload, Base64URL.
	GeolocationProofHash string `json:"geolocation-proof-hash,omitempty"`

	// "none" (raw location) or "zkp". Controls location privacy only.
	PrivacyTechnique string `json:"privacy-technique,omitempty"`

	// JSON-encoded inner location data. Structure depends on PrivacyTechnique.
	GeolocationPayload []byte `json:"geolocation-payload,omitempty"`

	// Chained freshness nonce: HMAC(secret, n || chain[n-1]).
	Nonce string `json:"nonce,omitempty"`

	// Unix epoch seconds.
	Timestamp int64 `json:"timestamp,omitempty"`

	// TPM2_Quote over qualifying data (Base64URL).
	TpmQuoteSeal string `json:"tpm-quote-seal,omitempty"`

	// SHA-256 digest of the Workload Identity Agent (SPIRE agent) binary.
	// Measured at attestation time to detect agent binary compromise.
	WorkloadIdentityAgentImageDigest string `json:"workload-identity-agent-image-digest,omitempty"`
}

// LAHMNOEndorsement replaces the old MNOEndorsement fields for lah-bundle use.
// The existing MNOEndorsement proto struct is retained for backward compat;
// this is the new structure used by LAHBundle-aware code paths.
type LAHMNOEndorsement struct {
	// MNO signing certificate (Base64URL DER).
	MnoKeyCert string `json:"mno-key-cert,omitempty"`

	// MNO signature over JCS(GeolocationPayload) only (Base64URL).
	MnoSig string `json:"mno-sig,omitempty"`
}
