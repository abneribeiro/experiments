SHELL := /bin/bash

DATABASE_URL ?= postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable
export DATABASE_URL

NAME ?= before
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

.DEFAULT_GOAL := help
.PHONY: help db-up db-down psql test run bench compare

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

db-up: ## Start PostgreSQL and wait until it is healthy
	docker compose up -d --wait

db-down: ## Stop PostgreSQL and delete its data
	docker compose down -v

psql: ## Open psql in the database container
	docker compose exec db psql -U postgres

test: ## Run Go tests with the race detector: one DIR, or every Go experiment
	@if [ -n "$(DIR)" ]; then \
		[ -f "$(DIR)/go.mod" ] || { echo "usage: make test [DIR=<folder with go.mod>]"; exit 1; }; \
		echo "==> $(DIR)"; cd "$(DIR)" && go test -race ./...; \
	else \
		failed=0; \
		for mod in */go.mod; do \
			[ -e "$$mod" ] || { echo "no Go experiments yet"; exit 0; }; \
			dir=$$(dirname "$$mod"); \
			case "$$dir" in _*) continue;; esac; \
			echo "==> $$dir"; \
			(cd "$$dir" && go test -race ./...) || failed=1; \
		done; \
		exit $$failed; \
	fi

run: ## Run a Go experiment: make run DIR=<folder>
	$(call require_dir,make run DIR=<folder>)
	cd "$(DIR)" && go run .

bench: ## Benchmark a Go experiment into DIR/NAME.txt: make bench DIR=<folder> [NAME=after]
	$(call require_dir,make bench DIR=<folder> [NAME=after])
	set -o pipefail; cd "$(DIR)" && go test -run='^$$' -bench=. -benchmem -count=10 ./... | tee "$(NAME).txt"

compare: ## Compare DIR/before.txt with DIR/after.txt: make compare DIR=<folder>
	$(call require_dir,make compare DIR=<folder>)
	$(BENCHSTAT) "$(DIR)/before.txt" "$(DIR)/after.txt"
