#!/usr/bin/env bash
# Shared helpers for derived add-on image builds from a base image.
set -euo pipefail

run_post_build_smoke_if_enabled() {
  local root_dir="$1"
  local image="$2"
  local run_post_build_tests="$3"
  local scope_label="$4"

  if [[ "$run_post_build_tests" == "true" ]]; then
    "$root_dir/scripts/test/smoke-test-image.sh" "$image"
  else
    echo "[$scope_label] Skipping post-build smoke tests (RUN_POST_BUILD_TESTS=$run_post_build_tests)"
  fi
}

build_base_via_pipeline() {
  local root_dir="$1"
  local release_tag="$2"
  local registry_prefix="$3"
  local base_image_name="$4"
  local run_post_build_tests="$5"

  local base_output
  base_output="$(qualify_image "$base_image_name" "$release_tag" "$registry_prefix")"

  # Step 1: Build the OS foundation layer (always starts FROM ubuntu:latest).
  local os_foundation
  os_foundation="${base_output}-foundation-${RANDOM}${RANDOM}"
  echo "[build] Building OS foundation..."
  docker build -t "$os_foundation" \
    -f "${root_dir}/scripts/build/components/ubuntu-base.Dockerfile" \
    "${root_dir}"

  # Step 2: Chain remaining base components on top of the OS foundation.
  # This is the full published base suite (not derived add-ons).
  local -a base_components=(python node visidata qsv readstat postgres duckdb qlever claude gemini)

  echo "[build] Assembling base image: $base_output"
  echo "[build] Components: ${base_components[*]}"
  build_composed_image "$root_dir" "$base_output" "$os_foundation" "${base_components[@]}"
  docker image rm -f "$os_foundation" >/dev/null 2>&1 || true

  run_post_build_smoke_if_enabled "$root_dir" "$base_output" "$run_post_build_tests" "build"
  echo "[build] Base image ready: $base_output"
}

qualify_image() {
  local image_name="$1"
  local release_tag="$2"
  local registry_prefix="$3"
  if [[ -n "$registry_prefix" ]]; then
    echo "${registry_prefix%/}/${image_name}:${release_tag}"
  else
    echo "${image_name}:${release_tag}"
  fi
}

ensure_base_image() {
  local root_dir="$1"
  local base_image="$2"
  local release_tag="$3"
  local registry_prefix="$4"
  local base_image_name="$5"
  local run_post_build_tests="$6"

  if docker image inspect "$base_image" >/dev/null 2>&1; then
    return 0
  fi

  echo "[build] Base image not found locally: $base_image"
  echo "[build] Building base image first..."
  build_base_via_pipeline "$root_dir" "$release_tag" "$registry_prefix" "$base_image_name" "$run_post_build_tests"
}

build_component_layer() {
  local root_dir="$1"
  local base_image="$2"
  local output_image="$3"
  local component="$4"

  local component_file="$root_dir/scripts/build/components/${component}.Dockerfile"
  if [[ ! -f "$component_file" ]]; then
    echo "[build] Component Dockerfile not found: $component_file" >&2
    return 1
  fi

  local -a build_cmd=(docker build --build-arg "BASE_IMAGE=$base_image")

  echo "[build] Applying component '$component' on top of $base_image"
  build_cmd+=(-t "$output_image" -f "$component_file" "$root_dir")
  "${build_cmd[@]}"
}

build_composed_image() {
  local root_dir="$1"
  local output_image="$2"
  local start_image="$3"
  shift 3
  local components=("$@")

  if (( ${#components[@]} == 0 )); then
    echo "[build] No components requested; tagging $start_image as $output_image"
    docker tag "$start_image" "$output_image"
    return 0
  fi

  local current_base="$start_image"
  local temp_images=()

  local idx=0
  local last_idx=$(( ${#components[@]} - 1 ))
  for component in "${components[@]}"; do
    local target_image
    if (( idx == last_idx )); then
      target_image="$output_image"
    else
      target_image="${output_image}-tmp-${component}-${RANDOM}${RANDOM}"
      temp_images+=("$target_image")
    fi

    build_component_layer "$root_dir" "$current_base" "$target_image" "$component"
    current_base="$target_image"
    idx=$((idx + 1))
  done

  if (( ${#temp_images[@]} > 0 )); then
    docker image rm -f "${temp_images[@]}" >/dev/null 2>&1 || true
  fi
}
