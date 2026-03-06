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

//! ZKP Prover CLI for Geofence Verification
//!
//! This binary provides a CLI interface for generating and verifying
//! privacy-preserving geofence proofs using Plonky2.

mod circuit;

use anyhow::Result;
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use clap::Parser;
use plonky2::field::types::Field;
use plonky2::plonk::config::PoseidonGoldilocksConfig;

type C = PoseidonGoldilocksConfig;
const D: usize = 2;

/// Scaling factor for fixed-point coordinate representation (6 decimal places)
const SCALING: f64 = 1_000_000.0;
/// Offset to make negative longitudes positive (add 180 degrees in scaled form)
const LON_OFFSET: u64 = 180_000_000;
/// Offset to make negative latitudes positive (add 90 degrees in scaled form)
const LAT_OFFSET: u64 = 90_000_000;

#[derive(Parser)]
#[command(name = "zkp-prover")]
#[command(about = "Privacy-preserving geofence ZKP prover (Plonky2)", long_about = None)]
struct Cli {
    // Legacy CLI flags for backward compatibility with service.py
    #[arg(long)]
    prove: bool,
    #[arg(long)]
    verify: bool,
    /// Verify proof cryptographically without needing geofence params
    #[arg(long)]
    verify_only: bool,
    #[arg(long)]
    lat: Option<f64>,
    #[arg(long)]
    lon: Option<f64>,
    #[arg(long)]
    id: Option<i64>,
    #[arg(long)]
    clat: Option<f64>,
    #[arg(long)]
    clon: Option<f64>,
    #[arg(long)]
    radius: Option<f64>,
    #[arg(long)]
    idhash: Option<i64>,
    #[arg(long)]
    proof: Option<String>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    if cli.prove {
        let lat = cli.lat.expect("--lat required for prove");
        let lon = cli.lon.expect("--lon required for prove");
        let id = cli.id.expect("--id required for prove");
        let clat = cli.clat.expect("--clat required for prove");
        let clon = cli.clon.expect("--clon required for prove");
        let radius = cli.radius.expect("--radius required for prove");
        let idhash = cli.idhash.expect("--idhash required for prove");
        return do_prove(lat, lon, id, clat, clon, radius, idhash);
    }

    if cli.verify {
        let proof = cli.proof.expect("--proof required for verify");
        let clat = cli.clat.expect("--clat required for verify");
        let clon = cli.clon.expect("--clon required for verify");
        let radius = cli.radius.expect("--radius required for verify");
        let idhash = cli.idhash.expect("--idhash required for verify");
        return do_verify(&proof, clat, clon, radius, idhash);
    }

    if cli.verify_only {
        let proof = cli.proof.expect("--proof required for verify-only");
        return do_verify_only(&proof);
    }

    eprintln!("Usage: zkp-prover --prove/--verify/--verify-only [options]");
    eprintln!("Run with --help for more information.");
    std::process::exit(1);
}

/// Scale and offset coordinates to positive u64 values
fn scale_coords(lat: f64, lon: f64, clat: f64, clon: f64, radius: f64) -> (u64, u64, u64, u64, u64) {
    // Scale and add offset to ensure positive values
    let lat_scaled = ((lat * SCALING) as i64 + LAT_OFFSET as i64) as u64;
    let lon_scaled = ((lon * SCALING) as i64 + LON_OFFSET as i64) as u64;
    let clat_scaled = ((clat * SCALING) as i64 + LAT_OFFSET as i64) as u64;
    let clon_scaled = ((clon * SCALING) as i64 + LON_OFFSET as i64) as u64;
    let radius_scaled = (radius * SCALING) as u64;
    (lat_scaled, lon_scaled, clat_scaled, clon_scaled, radius_scaled)
}

fn do_prove(lat: f64, lon: f64, id: i64, clat: f64, clon: f64, radius: f64, idhash: i64) -> Result<()> {
    let (lat_scaled, lon_scaled, clat_scaled, clon_scaled, radius_scaled) = 
        scale_coords(lat, lon, clat, clon, radius);

    // Build circuit and generate proof
    let (circuit_data, targets) = circuit::build_geofence_circuit();
    
    let proof = circuit::prove(
        &circuit_data,
        &targets,
        lat_scaled,
        lon_scaled,
        id as u64,
        clat_scaled,
        clon_scaled,
        radius_scaled,
        idhash as u64,
    )?;

    // Serialize proof to base64
    let proof_bytes = bincode::serialize(&proof)?;
    let proof_b64 = BASE64.encode(&proof_bytes);

    // Output proof (compatible with service.py expectation)
    println!("{}", proof_b64);
    Ok(())
}

fn do_verify(proof_b64: &str, clat: f64, clon: f64, radius: f64, idhash: i64) -> Result<()> {
    let (_, _, clat_scaled, clon_scaled, radius_scaled) = 
        scale_coords(0.0, 0.0, clat, clon, radius);

    // Decode proof
    let proof_bytes = BASE64.decode(proof_b64)?;
    let proof: plonky2::plonk::proof::ProofWithPublicInputs<
        plonky2::field::goldilocks_field::GoldilocksField,
        C,
        D,
    > = bincode::deserialize(&proof_bytes)?;

    // Rebuild circuit for verification (deterministic - same circuit every time)
    let (circuit_data, _) = circuit::build_geofence_circuit();

    // Verify public inputs match
    use plonky2::field::goldilocks_field::GoldilocksField;
    let expected_public = vec![
        GoldilocksField::from_canonical_u64(clat_scaled),
        GoldilocksField::from_canonical_u64(clon_scaled),
        GoldilocksField::from_canonical_u64(radius_scaled),
        GoldilocksField::from_canonical_u64(idhash as u64),
    ];

    if proof.public_inputs != expected_public {
        eprintln!("Proof INVALID: public inputs mismatch");
        std::process::exit(1);
    }

    // Verify proof
    match circuit::verify(&circuit_data, &proof) {
        Ok(true) => {
            println!("Proof VALID");
            Ok(())
        }
        _ => {
            eprintln!("Proof INVALID");
            std::process::exit(1)
        }
    }
}

/// Verify proof using only the embedded public inputs (no external params needed).
/// Prints the public inputs for transparency.
fn do_verify_only(proof_b64: &str) -> Result<()> {
    // Decode proof
    let proof_bytes = BASE64.decode(proof_b64)?;
    let proof: plonky2::plonk::proof::ProofWithPublicInputs<
        plonky2::field::goldilocks_field::GoldilocksField,
        C,
        D,
    > = bincode::deserialize(&proof_bytes)?;

    // Rebuild circuit for verification (deterministic)
    let (circuit_data, _) = circuit::build_geofence_circuit();

    // Print public inputs for transparency
    if proof.public_inputs.len() >= 4 {
        // GoldilocksField is a newtype wrapping u64; use .0 to extract the raw value
        let clat_raw = proof.public_inputs[0].0;
        let clon_raw = proof.public_inputs[1].0;
        let radius_raw = proof.public_inputs[2].0;
        let idhash_raw = proof.public_inputs[3].0;
        eprintln!("Public inputs (scaled): center_lat={}, center_lon={}, radius={}, idhash={}",
            clat_raw, clon_raw, radius_raw, idhash_raw);
    }

    // Verify proof cryptographically
    match circuit::verify(&circuit_data, &proof) {
        Ok(true) => {
            println!("Proof VALID");
            Ok(())
        }
        _ => {
            eprintln!("Proof INVALID");
            std::process::exit(1)
        }
    }
}
