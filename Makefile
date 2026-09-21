# ==============================================================================
# Unified Developer & Agent Harness Makefile
# System Design-to-Deployment Workflow Template
# ==============================================================================
# Single Source of Truth for local building, testing, linting, and orchestration.
# ==============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Colors for terminal output
BLUE   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
RESET  := \033[0m
BOLD   := \033[1m

SERVICES := services/api services/worker services/web

.PHONY: help
help: ## Display this target catalog and usage instructions
	@echo -e "$(BOLD)$(BLUE)System Design-to-Deployment Workflow Harness$(RESET)"
	@echo -e "Usage: make $(YELLOW)<target>$(RESET)\n"
	@echo -e "$(BOLD)Available Targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-16s$(RESET) %s\n", $$1, $$2}'
	@echo ""

.PHONY: verify
verify: lint typecheck test ## Single source of truth: Run linting, syntax, and test suites
	@echo -e "\n$(BOLD)$(GREEN)============================================================$(RESET)"
	@echo -e "$(BOLD)$(GREEN)✔ [VERIFY PASSED] All lints, syntax checks, and tests succeeded!$(RESET)"
	@echo -e "$(BOLD)$(GREEN)============================================================$(RESET)\n"

.PHONY: lint
lint: ## Lint source code across all services
	@echo -e "$(BLUE)▶ Linting services code...$(RESET)"
	@for dir in $(SERVICES); do \
		echo -e "  $(YELLOW)Checking $$dir...$(RESET)"; \
		(cd $$dir && npm run lint) || exit 1; \
	done
	@echo -e "$(GREEN)✔ Linting completed successfully across all services.$(RESET)"

.PHONY: typecheck
typecheck: ## Perform syntax and static validation across all services
	@echo -e "$(BLUE)▶ Validating JavaScript syntax...$(RESET)"
	@find services/api/src services/api/test -name "*.js" -exec node --check {} +
	@find services/worker/src services/worker/test -name "*.js" -exec node --check {} +
	@find services/web/src services/web/test services/web/public -name "*.js" -exec node --check {} +
	@echo -e "$(GREEN)✔ Syntax check passed cleanly.$(RESET)"

.PHONY: test
test: ## Run unit and integration test suites across all services
	@echo -e "$(BLUE)▶ Running test suites...$(RESET)"
	@for dir in $(SERVICES); do \
		echo -e "\n$(BOLD)------------------------------------------------------------$(RESET)"; \
		echo -e "$(BOLD)$(BLUE)Running tests in $$dir$(RESET)"; \
		echo -e "$(BOLD)------------------------------------------------------------$(RESET)"; \
		(cd $$dir && npm test) || exit 1; \
	done
	@echo -e "\n$(GREEN)✔ All test suites passed successfully!$(RESET)"

.PHONY: docker-build
docker-build: ## Build multi-stage container images for all services
	@echo -e "$(BLUE)▶ Building Docker container images...$(RESET)"
	docker compose build

.PHONY: docker-up
docker-up: ## Launch full containerized environment with health waiting
	@echo -e "$(BLUE)▶ Starting containerized services (postgres, pubsub, api, worker, web)...$(RESET)"
	docker compose up -d --build --wait
	@echo -e "\n$(GREEN)✔ All container services are up and healthy!$(RESET)"
	@docker compose ps

.PHONY: docker-down
docker-down: ## Stop containers and remove volumes, networks, and orphans
	@echo -e "$(YELLOW)▶ Tearing down containerized environment and volumes...$(RESET)"
	docker compose down -v --remove-orphans
	@echo -e "$(GREEN)✔ Cleanup complete.$(RESET)"

.PHONY: docker-ps
docker-ps: ## List status of running container services
	docker compose ps

.PHONY: docker-logs
docker-logs: ## Tail live log output across all running containers
	docker compose logs -f

.PHONY: clean
clean: ## Remove temporary build caches, logs, and coverage reports
	@echo -e "$(YELLOW)▶ Removing build caches and temporary artifacts...$(RESET)"
	@rm -rf */node_modules/.cache
	@rm -rf */coverage
	@rm -rf .tmp
	@find . -type f -name "*.log" -not -path "./.git/*" -delete
	@echo -e "$(GREEN)✔ Workspace cleaned.$(RESET)"
