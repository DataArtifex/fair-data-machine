# FAIR Data Machine

Welcome to the High-Value Data FAIRification machine.

This project provides a practical “toolkit in a box” for turning raw data into reusable digital products. It leverages a modern, data-driven architecture to generate optimized Docker workstations tailored to your specific FAIRification needs.

## 🚀 Quick Start

The FAIR Data Machine is now fully customizable. You can use the built-in Builder UI to select exactly the tools and packages you need.

### 1. Launch the Builder
```bash
python3 scripts/ui/app.py
```

### 2. Generate and Build
- Select your components (Python, Postgres, DuckDB, R, AI tools, etc.).
- Pick specific Python/R packages from the dynamic dropdowns.
- Click **Generate Build Package**.
- Follow the instructions in the newly created `custom-build/` directory to build your image.
+
+> [!TIP]
+> The `custom-build/` directory is **overwritten** every time you generate a new build package. If you want to keep a specific version, simply rename the folder (e.g., `mv custom-build my-special-build`) before clicking generate again.

---

## 🛠 Features & Components

The machine is powered by a central **Component Registry** (`config/components.json`). Available tools include:

### Languages & Runtimes
- **Python 3.12**: Fast dependency management via `uv`.
- **Node.js (LTS)**: JavaScript runtime with `pnpm`.
- **R**: Statistical computing layer with custom package support.

### Databases & Query Engines
- **PostgreSQL + pgvector**: Relational storage with vector similarity search.
- **DuckDB**: Embedded analytical SQL engine.
- **QLever**: RDF/SPARQL-oriented query engine.
- **Oxygraph**: Lightweight RDF graph database.

### Analytical Tools
- **VisiData**: Terminal-first interactive data exploration.
- **QSV**: High-performance CSV toolkit.
- **ReadStat**: Interoperability for legacy statistical formats (SPSS/Stata/SAS).

### AI Assistants (Optional)
- **Claude Code CLI**: Anthropic's terminal-based AI coding assistant.
- **Gemini CLI**: Google's AI assistant for automation and scripting.

---

## 📂 Project Structure

- `config/components.json`: Central registry of all tool installation logic and metadata.
- `scripts/runtime/generator.py`: Optimized build generator that produces clean, single-stage Dockerfiles.
- `scripts/ui/app.py`: Interactive Gradio interface for image customization.
- `custom-build/`: The output directory for your generated workstation files.
- `docs/OFFLINE.md`: Step-by-step guide for air-gapped deployment.
- `docs/MAINTENANCE_GUIDE.md`: Instructions for expanding the registry and UI.

---

## 👩‍💻 For Maintainers

The architecture is designed to be highly extensible. Adding a new tool or updating a package version only requires editing a single JSON file.

Refer to the [MAINTENANCE_GUIDE.md](docs/MAINTENANCE_GUIDE.md) for details on adding components, resolving dependencies, and updating the UI.

---

> [!IMPORTANT]
> **Early Prototype**: This project is in an early stage. Expect breaking changes and limited documentation as we refine the FAIRification workflows.
