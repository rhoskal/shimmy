# AGENTS.md

## Project Overview
Shimmy is a tool to convert high-fidelity audio formats (`DTS-HD MA`, `DTS:X`, `TrueHD`) into a universally compatible format (`EAC3`) for mobile playback, while preserving the original audio track.

## Tech Stack
- **Language:** OCaml
- **Build System:** Dune
- **Environment/Package Management:** Nix (via Flakes), OPAM
- **Dependencies:** Requires `ffprobe` (part of FFmpeg) for processing.

## Project Structure
- `bin/`: Command-line interface (CLI) implementation.
- `lib/`: Core business logic and library modules.
- `test/`: Test suites for ensuring correctness.
- `justfile`: Task automation for common operations.
- `dune-project`: Dune build system configuration.
- `flake.nix`: Nix development environment configuration.

## Common Commands
- **Build project:** `just build`
- **Install dependencies:** `just install`
- **Run tests:** `just test`
- **Enter development environment:** `nix develop`

## Coding Standards
- Use `dune` for building, testing, and managing dependencies.
- Maintain clear separation between the core library (`lib/`) and the CLI (`bin/`).
- Follow standard OCamly/Dune project conventions.
- Ensure new features are covered by tests in the `test/` directory.
