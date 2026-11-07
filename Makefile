SHELL := /bin/bash

DATABASE_URL ?= postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable
export DATABASE_URL

NAME ?= before
KIND ?= go
MODULE_PREFIX := github.com/abneribeiro/experiments
BENCHSTAT ?= $(shell command -v benchstat || echo "$$(go env GOPATH)/bin/benchstat")

# Fails with a usage line when DIR is missing or is not a directory.
# $(1) is the usage example.
define require_dir
	@if [ -z "$(DIR)" ] || [ ! -d "$(DIR)" ]; then \
		echo "usage: $(1)"; \
		[ -n "$(DIR)" ] && echo "error: '$(DIR)' is not a directory"; \
		exit 1; \
	fi
endef

# Tests one experiment folder, Go or Bun. $(1) is the folder.
define test_one
	if [ -f "$(1)/go.mod" ]; then \
		(cd "$(1)" && go test -race ./...); \
	elif [ -f "$(1)/package.json" ]; then \
		(cd "$(1)" && { [ -d node_modules ] || bun install --frozen-lockfile; } && bun test && bunx tsc --noEmit); \
	else \
		echo "no go.mod or package.json: nothing to test"; \
	fi
endef

.DEFAULT_GOAL := help
.PHONY: help new db-up db-down psql test run bench compare

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

new: ## Start an experiment: make new DIR=01-webhook-hmac [KIND=go|ts|sql]
	@if ! [[ "$(DIR)" =~ ^[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$$ ]]; then \
		echo "usage: make new DIR=NN-topic-subject [KIND=go|ts|sql]"; exit 1; \
	fi
	@if [ -e "$(DIR)" ]; then echo "error: '$(DIR)' already exists"; exit 1; fi
	@case "$(KIND)" in \
		go) cp -R _template "$(DIR)" \
			&& (cd "$(DIR)" && go mod edit -module "$(MODULE_PREFIX)/$(DIR)");; \
		ts) mkdir "$(DIR)" \
			&& cp _template/README.md _template/NOTES.md "$(DIR)/" \
			&& for f in package.json bun.lock tsconfig.json index.ts index.test.ts bench.ts; do cp "_template-ts/$$f" "$(DIR)/"; done \
			&& sed -i '' 's/"name": "experiment"/"name": "$(DIR)"/' "$(DIR)/package.json" \
			&& (cd "$(DIR)" && bun install --frozen-lockfile);; \
		sql) mkdir "$(DIR)" && cp _template/README.md _template/NOTES.md "$(DIR)/";; \
		*) echo "error: KIND must be go, ts or sql"; exit 1;; \
	esac
	@echo "created $(DIR) ($(KIND)): start with NOTES.md, then the question in README.md"

db-up: ## Start PostgreSQL and wait until it is healthy
	docker compose up -d --wait

db-down: ## Stop PostgreSQL and delete its data
	docker compose down -v

psql: ## Open psql in the database container
	docker compose exec db psql -U postgres

test: ## Run tests (Go: -race; Bun: bun test + tsc): one DIR, or every experiment
	@if [ -n "$(DIR)" ]; then \
		[ -d "$(DIR)" ] || { echo "usage: make test [DIR=<folder>]"; exit 1; }; \
		echo "==> $(DIR)"; $(call test_one,$(DIR)); \
	else \
		failed=0; found=0; \
		for dir in */; do \
			dir=$${dir%/}; \
			case "$$dir" in _*) continue;; esac; \
			[ -f "$$dir/go.mod" ] || [ -f "$$dir/package.json" ] || continue; \
			found=1; echo "==> $$dir"; \
			( $(call test_one,$$dir) ) || failed=1; \
		done; \
		[ $$found = 1 ] || echo "no experiments yet"; \
		exit $$failed; \
	fi

run: ## Run an experiment: make run DIR=<folder>
	$(call require_dir,make run DIR=<folder>)
	@if [ -f "$(DIR)/package.json" ]; then cd "$(DIR)" && bun run index.ts; else cd "$(DIR)" && go run .; fi

bench: ## Benchmark into DIR/NAME.txt: make bench DIR=<folder> [NAME=after]
	$(call require_dir,make bench DIR=<folder> [NAME=after])
	@set -o pipefail; \
	if [ -f "$(DIR)/package.json" ]; then \
		cd "$(DIR)" && NO_COLOR=1 bun run bench.ts | tee "$(NAME).txt"; \
	else \
		cd "$(DIR)" && go test -run='^$$' -bench=. -benchmem -count=10 ./... | tee "$(NAME).txt"; \
	fi

compare: ## Compare DIR/before.txt with DIR/after.txt: make compare DIR=<folder>
	$(call require_dir,make compare DIR=<folder>)
	@if [ -f "$(DIR)/package.json" ]; then \
		diff -y -W 160 "$(DIR)/before.txt" "$(DIR)/after.txt" || true; \
	else \
		$(BENCHSTAT) "$(DIR)/before.txt" "$(DIR)/after.txt"; \
	fi
