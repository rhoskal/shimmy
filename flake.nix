{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages =
              with pkgs;
              [
                nixd
                nixfmt
                ocaml
                ocamlformat
                opam
              ]
              ++ (with pkgs.ocamlPackages; [
                dune_3
                odoc
              ])
              ++ (
                if stdenv.isLinux then
                  [
                    inotify-tools
                    libnotify
                  ]
                else if stdenv.isDarwin then
                  [
                    terminal-notifier
                    apple-sdk
                  ]
                else
                  [ ]
              );

            shellHook = ''
              mkdir -p .nix-opam

              export LC_ALL=en_US.UTF-8
              export OPAMROOT=$(pwd)/.nix-opam

              # One-time initialization (idempotent)
              if [ ! -f "$OPAMROOT/config" ]; then
                opam init --no-setup --bare -y --root "$OPAMROOT"
              fi

              # Create/activate a local switch using the same OCaml version as Nix provides
              if ! opam switch list --short | grep -q "^default$"; then
                opam switch create default "$(ocamlc -vnum)" -y
              fi

              # Activate the opam environment
              eval $(opam env)

              # Automatically install common dev tools
              opam install --deps-only . -y
              opam install utop ocaml-lsp-server -y
            '';
          };
        }
      );
    };
}
