SHELL := /bin/bash

RELEASE_TAG ?= dev
REGISTRY_PREFIX ?=
TOOLCHAIN_IMAGE_NAME ?= kulnor/fair-data-machine
TOOLCHAIN_IMAGE_NAME_OLLAMA ?= kulnor/fair-data-machine-ollama
PUSH_TO_REGISTRY ?= false
ARTIFACT_DIR ?= release/$(RELEASE_TAG)
RUN_POST_BUILD_TESTS ?= true
TEST_IMAGE ?= $(if $(REGISTRY_PREFIX),$(REGISTRY_PREFIX)/$(TOOLCHAIN_IMAGE_NAME):$(RELEASE_TAG),$(TOOLCHAIN_IMAGE_NAME):$(RELEASE_TAG))

.PHONY: help build-release build-release-ollama build-release-no-ollama test-image export-release import-release import-release-push release-all

help:
	@echo "Targets:"
	@echo "  make build-release        Build base image (all base components)"
	@echo "  make build-release-ollama Build base + Ollama add-on"
	@echo "  make test-image           Run smoke tests against TEST_IMAGE"
	@echo "  export-release            Export image tar artifacts + checksums + manifest"
	@echo "  import-release            Import release tar artifacts from ARTIFACT_DIR"
	@echo "  import-release-push       Import and push to REGISTRY_PREFIX"
	@echo "  release-all               Build and export in one step"
	@echo ""
	@echo "Common variables (override as needed):"
	@echo "  RELEASE_TAG=$(RELEASE_TAG)"
	@echo "  REGISTRY_PREFIX=$(REGISTRY_PREFIX)"
	@echo "  ARTIFACT_DIR=$(ARTIFACT_DIR)"
	@echo "  RUN_POST_BUILD_TESTS=$(RUN_POST_BUILD_TESTS)"
	@echo "  TEST_IMAGE=$(TEST_IMAGE)"
	@echo ""
	@echo "Add-on preset scripts (user-invoked, not in default CI):"
	@echo "  scripts/build/r.sh"
	@echo "  scripts/build/ollama.sh"
	@echo "  scripts/build/ollama-r.sh"

build-release:
	@RELEASE_TAG="$(RELEASE_TAG)" \
	REGISTRY_PREFIX="$(REGISTRY_PREFIX)" \
	TOOLCHAIN_IMAGE_NAME="$(TOOLCHAIN_IMAGE_NAME)" \
	RUN_POST_BUILD_TESTS="$(RUN_POST_BUILD_TESTS)" \
	./scripts/deployment/build-release-images.sh

build-release-ollama:
	@RELEASE_TAG="$(RELEASE_TAG)" \
	REGISTRY_PREFIX="$(REGISTRY_PREFIX)" \
	TOOLCHAIN_IMAGE_NAME="$(TOOLCHAIN_IMAGE_NAME_OLLAMA)" \
	RUN_POST_BUILD_TESTS="$(RUN_POST_BUILD_TESTS)" \
	./scripts/build/ollama.sh

build-release-no-ollama: build-release

test-image:
	@./scripts/test/smoke-test-image.sh "$(TEST_IMAGE)"

export-release:
	@RELEASE_TAG="$(RELEASE_TAG)" \
	REGISTRY_PREFIX="$(REGISTRY_PREFIX)" \
	TOOLCHAIN_IMAGE_NAME="$(TOOLCHAIN_IMAGE_NAME)" \
	OUT_DIR="$(ARTIFACT_DIR)" \
	./scripts/deployment/export-release-artifacts.sh

import-release:
	@./scripts/deployment/import-release-artifacts.sh "$(ARTIFACT_DIR)"

import-release-push:
	@PUSH_TO_REGISTRY=true \
	REGISTRY_PREFIX="$(REGISTRY_PREFIX)" \
	./scripts/deployment/import-release-artifacts.sh "$(ARTIFACT_DIR)"

release-all: build-release export-release
