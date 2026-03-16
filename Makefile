SHELL := /bin/bash

RELEASE_TAG ?= dev
REGISTRY_PREFIX ?=
IMAGE_NAME ?= my-custom-machine
TEST_IMAGE ?= $(if $(REGISTRY_PREFIX),$(REGISTRY_PREFIX)/$(IMAGE_NAME):$(RELEASE_TAG),$(IMAGE_NAME):$(RELEASE_TAG))

ARTIFACT_DIR ?= release/$(RELEASE_TAG)

.PHONY: help ui dev build-custom test-image export-release import-release import-release-push

help:
	@echo "FAIR Data Machine Targets:"
	@echo "  make ui           Launch the Builder UI (Gradio)"
	@echo "  make dev          Launch the UI in hot-reload mode (for development)"
	@echo "  make build-custom Build the custom image generated in custom-build/"
	@echo "  make test-image   Run smoke tests against TEST_IMAGE from custom-build/"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo "  TEST_IMAGE=$(TEST_IMAGE)"

ui:
	@python3 scripts/ui/app.py

dev:
	@gradio scripts/ui/app.py

build-custom:
	@if [ ! -d "custom-build" ]; then echo "Error: custom-build/ directory not found. Run 'make ui' first." && exit 1; fi
	cd custom-build && docker build -t $(TEST_IMAGE) .

test-image:
	@if [ ! -f "custom-build/test-image.sh" ]; then echo "Error: custom-build/test-image.sh not found. Run 'make ui' first." && exit 1; fi
	./custom-build/test-image.sh "$(TEST_IMAGE)"
