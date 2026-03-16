# Offline Deployment Guide

This guide describes how to deploy custom FAIR Data Machine workstations in secure, air-gapped, or no-internet environments.

## Core Principle: Build Online, Run Offline

The FAIR Data Machine Builder requires internet access to download system packages, binaries (DuckDB, QLever, etc.), and language specific packages (pip, npm, pnpm, R).

**The build process itself MUST happen in a "Connected Zone".** Once the Docker image is built, it can be exported and transferred to the "Secure Zone".

---

## 1. Connected Zone: Preparation

### A. Generate and Build
1. Launch the Builder: `make dev`
2. Select your components and packages in the UI.
3. Click **Generate Build Package**.
4. Build the image in the generated directory:
   ```bash
   cd custom-build
   docker build -t fair-data-machine:offline .
   ```

### B. Verify
Run the smoke tests to ensure everything is functional before export:
```bash
./test-image.sh fair-data-machine:offline
```

### C. Export
Save the image as a tar archive:
```bash
docker save -o fair-data-machine_offline.tar fair-data-machine:offline
```

---

## 2. Transfer Boundary

Transfer the following artifacts to the secure environment using your approved media (e.g., encrypted USB, internal transfer gateway):
- `fair-data-machine_offline.tar`
- (Optional) `test-image.sh` and `smoke-test.sh` for final verification.

---

## 3. Secure Zone: Deployment

### A. Load the Image
On the target host in the secure environment:
```bash
docker load -i fair-data-machine_offline.tar
```

### B. Launch the Workstation
Run the workstation with your local workspace mounted. Ensure you log in as the `dartfx` user:
```bash
docker run --rm -it \
  -v "$(pwd)":/home/dartfx/workspace \
  fair-data-machine:offline \
  su - dartfx
```

### C. (Optional) Registry Push
If your environment uses a local private registry (e.g., Harbor, Artifactory), tag and push the image:
```bash
docker tag fair-data-machine:offline registry.internal/kulnor/fair-data-machine:latest
docker push registry.internal/kulnor/fair-data-machine:latest
```

---

## 4. Special Handling: Ollama Models

If your image includes **Ollama**, models must also be transferred offline:
1. **Online**: Pull the model (`ollama pull gpt-oss:20b`).
2. **Online**: Locate the model files (usually `/var/lib/ollama/models`) and archive them.
3. **Offline**: Transfer the archive and mount it to the container's `/var/lib/ollama/models` directory.

Example launch with offline model storage:
```bash
docker run --rm -it \
  -v "$(pwd)":/home/dartfx/workspace \
  -v /path/to/offline/models:/var/lib/ollama/models \
  fair-data-machine:offline \
  su - dartfx
```
