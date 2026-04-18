# Shimmy development helpers

# Introspection targets
# ---------------------

.PHONY: help
help: ## Show this help message
	@echo "Usage: make <target>"
	@echo ""
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Make `make` with no arguments show the help by default
.DEFAULT_GOAL := help

# Build targets
# -------------------

.PHONY: build
build: ## Build the project
	dune build

.PHONY: clean
clean: ## Clean build artifacts
	dune clean

.PHONY: install
install:
	opam install . --deps-only --with-test --yes

.PHONY: run
run: ## Run the executable (use ARGS='...' to pass arguments)
	dune exec -- shimmy $(ARGS)

.PHONY: watch
watch: ## Build and watch for changes
	dune build --watch

# Development targets
# -------------------
.PHONY: fmt
fmt: ## Format code
	dune fmt

.PHONY: repl
repl: ## Start an interactive REPL (`Ctrl + D` to exit)
	dune utop .

.PHONY: test
test: ## Run tests
	dune runtest
