# Shimmy

Take high-fidelity audio formats (`DTS-HD MA`, `DTS:X`, `TrueHD`) and convert
them into a universally compatible format (EAC3) for mobile playback,
preserving the original audio track.

## Development setup

1. Enter the Nix shell: `nix develop` (or let `direnv` do it automatically)
2. Before installing, make sure your package index is up to date: `opam update`
3. Then install the project's dependencies: `just install`
4. Build project: `just build`
