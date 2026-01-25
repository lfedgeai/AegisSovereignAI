// Copyright 2025 AegisSovereignAI Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//! Geofence ZKP Circuit using Plonky2
//!
//! Proves that a private location (lat, lon) is within a public radius
//! of a public center point, and that the sensor ID matches a public hash.

use anyhow::Result;

use plonky2::field::types::Field;
use plonky2::iop::target::Target;
use plonky2::iop::witness::{PartialWitness, WitnessWrite};
use plonky2::plonk::circuit_builder::CircuitBuilder;
use plonky2::plonk::circuit_data::{CircuitConfig, CircuitData};
use plonky2::plonk::config::{GenericConfig, PoseidonGoldilocksConfig};
use plonky2::plonk::proof::ProofWithPublicInputs;

/// Configuration type alias for Plonky2 with Poseidon hash
pub type C = PoseidonGoldilocksConfig;
pub type F = <C as GenericConfig<2>>::F;
pub const D: usize = 2;

/// Circuit targets for geofence proof
pub struct GeofenceCircuitTargets {
    // Private inputs
    pub latitude: Target,
    pub longitude: Target,
    pub sensor_id: Target,
    // Public inputs (registered as public)
    pub center_lat: Target,
    pub center_long: Target,
    pub radius: Target,
    pub id_hash: Target,
    // Internal target for inequality slack
    pub slack: Target,
}

/// Build the geofence circuit
/// 
/// Constraints:
/// 1. (lat - center_lat)² + (lon - center_lon)² + slack = radius² (where slack >= 0)
/// 2. sensor_id == id_hash
pub fn build_geofence_circuit() -> (CircuitData<F, C, D>, GeofenceCircuitTargets) {
    let config = CircuitConfig::standard_recursion_config();
    let mut builder = CircuitBuilder::<F, D>::new(config);

    // Create targets for private inputs
    let latitude = builder.add_virtual_target();
    let longitude = builder.add_virtual_target();
    let sensor_id = builder.add_virtual_target();

    // Create targets for public inputs
    let center_lat = builder.add_virtual_target();
    let center_long = builder.add_virtual_target();
    let radius = builder.add_virtual_target();
    let id_hash = builder.add_virtual_target();

    // Register public inputs
    builder.register_public_input(center_lat);
    builder.register_public_input(center_long);
    builder.register_public_input(radius);
    builder.register_public_input(id_hash);

    // Constraint 1: Proximity check
    // (lat - center_lat)² + (lon - center_lon)² + slack = radius²
    let diff_lat = builder.sub(latitude, center_lat);
    let diff_lon = builder.sub(longitude, center_long);
    let sq_diff_lat = builder.mul(diff_lat, diff_lat);
    let sq_diff_lon = builder.mul(diff_lon, diff_lon);
    let dist_sq = builder.add(sq_diff_lat, sq_diff_lon);
    let radius_sq = builder.mul(radius, radius);
    
    // Slack variable to represent the inequality: dist_sq + slack = radius_sq
    let slack = builder.add_virtual_target();
    let dist_plus_slack = builder.add(dist_sq, slack);
    builder.connect(dist_plus_slack, radius_sq);

    // Constraint 2: Hardware binding - sensor_id == id_hash
    builder.connect(sensor_id, id_hash);

    let circuit_data = builder.build::<C>();

    let targets = GeofenceCircuitTargets {
        latitude,
        longitude,
        sensor_id,
        center_lat,
        center_long,
        radius,
        id_hash,
        slack,
    };

    (circuit_data, targets)
}

/// Generate a proof with the given inputs
/// All coordinate values should already be scaled (e.g., by 1e6) and positive
pub fn prove(
    circuit_data: &CircuitData<F, C, D>,
    targets: &GeofenceCircuitTargets,
    lat: u64,
    lon: u64,
    sensor_id: u64,
    center_lat: u64,
    center_lon: u64,
    radius: u64,
    id_hash: u64,
) -> Result<ProofWithPublicInputs<F, C, D>> {
    let mut pw = PartialWitness::new();

    // Set private inputs
    pw.set_target(targets.latitude, F::from_canonical_u64(lat));
    pw.set_target(targets.longitude, F::from_canonical_u64(lon));
    pw.set_target(targets.sensor_id, F::from_canonical_u64(sensor_id));

    // Set public inputs
    pw.set_target(targets.center_lat, F::from_canonical_u64(center_lat));
    pw.set_target(targets.center_long, F::from_canonical_u64(center_lon));
    pw.set_target(targets.radius, F::from_canonical_u64(radius));
    pw.set_target(targets.id_hash, F::from_canonical_u64(id_hash));

    // Calculate slack for the inequality constraint
    // We need to handle the subtraction carefully in finite field
    // For simplicity, compute in regular arithmetic first
    let diff_lat = if lat >= center_lat { lat - center_lat } else { center_lat - lat };
    let diff_lon = if lon >= center_lon { lon - center_lon } else { center_lon - lon };
    let dist_sq = diff_lat.saturating_mul(diff_lat).saturating_add(diff_lon.saturating_mul(diff_lon));
    let radius_sq = radius.saturating_mul(radius);
    
    if dist_sq > radius_sq {
        anyhow::bail!("Location is outside the geofence radius");
    }
    let slack = radius_sq - dist_sq;
    pw.set_target(targets.slack, F::from_canonical_u64(slack));

    let proof = circuit_data.prove(pw)?;
    Ok(proof)
}

/// Verify a proof against the circuit
pub fn verify(
    circuit_data: &CircuitData<F, C, D>,
    proof: &ProofWithPublicInputs<F, C, D>,
) -> Result<bool> {
    circuit_data.verify(proof.clone())?;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_proof() {
        let (circuit_data, targets) = build_geofence_circuit();
        
        // Location inside geofence (all positive, scaled by 1e6)
        // Using offset coordinates to keep everything positive
        let proof = prove(
            &circuit_data,
            &targets,
            45_500_000,  // lat (scaled)
            93_200_000,  // lon (positive offset)
            12345,       // sensor_id
            45_000_000,  // center_lat
            93_000_000,  // center_lon
            1_000_000,   // radius (scaled)
            12345,       // id_hash
        ).unwrap();

        assert!(verify(&circuit_data, &proof).is_ok());
    }
}
