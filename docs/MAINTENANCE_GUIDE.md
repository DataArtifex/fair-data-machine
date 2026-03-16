# Maintenance Guide: FAIR Data Machine Builder

This guide explains how to maintain, update, and extend the Builder tool.

## Project Structure
- `config/components.json`: The source of truth for all tools and packages.
- `scripts/runtime/generator.py`: The logic that converts JSON metadata into a Docker build directory.
- `scripts/ui/app.py`: The Gradio interface.

---

## 1. Maintaining the UI (`app.py`)
The UI is **data-driven**. You rarely need to touch `app.py` unless you want to change the layout or theme.

### How to Run
```bash
make ui
```

### Dev Mode (Hot Reload)
To have the UI automatically reload when you change `app.py` or `components.json`:
```bash
make dev
```

### Adding New Categories
If you add a new category in `components.json` (e.g., `"security"`), the UI will automatically group components under that category without any code changes.

---

## 2. Managing Components (`components.json`)
This file defines everything the machine can do.

### Adding a New Tool
To add a tool (e.g., `Oxygraph`), add a new entry to the JSON:
```json
"oxygraph": {
  "name": "Oxygraph",
  "category": "database",
  "install": [
    "curl -fsSL https://github.com/.../oxigraph -o /usr/local/bin/oxigraph",
    "chmod +x /usr/local/bin/oxigraph"
  ]
}
```

### Adding Package Options
To add a new library to the Python or R dropdowns, update the `sub_selection` object:
```json
"sub_selection": {
  "options": [
    {"name": "new-package-name", "group": "optional"}
  ]
}
```

---

## 3. Maintaining the Generator (`generator.py`)
The generator handles dependency resolution and file mounting.

### Dependency Logistics
If a component depends on another (e.g., a tool that needs Node.js), ensure the `"dependencies": ["node"]` field is set in `components.json`. The generator uses a recursive "visit" algorithm to ensure the parents are installed before the children.

### Optimizing Layering
All `system_packages` across all selected components are automatically deduplicated and sorted into a single `RUN apt-get install` command at the top of the Dockerfile. To keep builds clean, always prefer adding system dependencies to the `system_packages` list rather than putting `apt install` inside the `install` script array.

---

## 4. Updates & Security
- **Version Pinning**: When possible, use variables like `${QSV_VERSION}` in the `install` steps to make updates easier.
- **Base Image**: The generator currently uses `FROM ubuntu:latest`. To update the base OS, change the hardcoded string in `generator.py` or move it to a config variable.
