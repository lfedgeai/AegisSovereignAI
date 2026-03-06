# Contributing to AegisSovereignAI

Thank you for your interest in contributing to AegisSovereignAI! This project implements hardware-rooted, privacy-preserving workload identity and geolocation verification using TPM 2.0, SPIRE, Keylime, and Zero-Knowledge Proofs.

## Getting Started

1. **Fork** the repository and clone your fork.
2. **Install prerequisites**: `./install_prerequisites.sh`
3. **Run the demo**: `./run-demo.sh`
4. See [README-arch-sovereign-unified-identity.md](README-arch-sovereign-unified-identity.md) for architecture details.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or request features.
- Include steps to reproduce, expected vs. actual behavior, and your environment (OS, TPM type, etc.).

### Submitting Changes

1. Create a feature branch from `main`: `git checkout -b feature/my-change`
2. Make your changes, following the existing code style.
3. Test your changes: `./run-demo.sh`
4. Submit a Pull Request with a clear description of what changed and why.

### Areas We Welcome Contributions

- **Hardware support**: Additional TPM vendors, GNSS/GPS sensor integrations
- **ZKP circuits**: New geofence geometries, proof optimizations
- **Documentation**: Architecture diagrams, setup guides, translations
- **Testing**: CI improvements, edge-case test scenarios
- **Standards alignment**: IETF WIMSE draft implementations

## Code of Conduct

This project follows the [LF Edge Code of Conduct](https://lfprojects.org/policies/code-of-conduct/). Please be respectful and constructive in all interactions.

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
