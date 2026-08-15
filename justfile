# 📖 Run `just -l` to see all available commands
# 📖 Run `just --dry-run <recipe>` to preview commands without executing

# Default recipe
default: help

# Show all commands
help:
    @just --list

# ──────────────────────────────────────────────────────────────
# 📦 Build & Release
# ──────────────────────────────────────────────────────────────

# Build the project
build:
    dune build @install

# Generate release artifacts
release:
    dune build @install --profile=release

# Clean build artifacts
clean:
    dune clean

# ──────────────────────────────────────────────────────────────
# 🛠️ Development
# ──────────────────────────────────────────────────────────────

# Install project dependencies
install:
    opam install . --deps-only --with-test --yes

# Run the executable (pass arguments via: just run <args>)
run args:
    dune exec -- shimmy {{args}}

# Build and watch for changes
watch:
    dune build --watch

# Format code
fmt:
    dune fmt

# Start an interactive REPL
repl:
    dune utop .

# ──────────────────────────────────────────────────────────────
# 🧪 Testing
# ──────────────────────────────────────────────────────────────

# Run tests
test:
    dune runtest
