import gradio as gr
import json
from pathlib import Path
import sys

# Add generator to path
sys.path.append(str(Path(__file__).parent.parent / "runtime"))
from generator import DockerfileGenerator

REGISTRY_PATH = Path(__file__).parent.parent.parent / "config" / "components.json"
OUTPUT_DIR = Path(__file__).parent.parent.parent / "custom-build"

def load_components():
    with open(REGISTRY_PATH, 'r') as f:
        return json.load(f)

PROFILE_DIR = Path(__file__).parent.parent.parent / "profiles"

def get_profiles():
    if not PROFILE_DIR.exists():
        return []
    
    profiles = sorted([f.stem for f in PROFILE_DIR.glob("*.json")])
    if "baseline-workstation" in profiles:
        profiles.remove("baseline-workstation")
        profiles.insert(0, "baseline-workstation")
    return profiles

def generate_build_package(selected_tools, *variadic_inputs):
    gen = DockerfileGenerator(REGISTRY_PATH)
    comps = load_components()
    
    # variadic_inputs contains [ctrl1, custom_ctrl1, ctrl2, custom_ctrl2, ...]
    # based on components that have sub_selection
    sub_sel_comps = [k for k, v in comps.items() if "sub_selection" in v]
    
    pkg_map = {}
    for i, comp_id in enumerate(sub_sel_comps):
        if comp_id in selected_tools:
            # Checkbox results (list)
            selected_pkgs = list(variadic_inputs[i*2])
            # Textbox results (string)
            custom_pkgs_str = variadic_inputs[i*2 + 1]
            if custom_pkgs_str:
                # Split by comma or space and filter empty
                custom_pkgs = [p.strip() for p in custom_pkgs_str.replace(",", " ").split() if p.strip()]
                selected_pkgs.extend(custom_pkgs)
            
            pkg_map[comp_id] = list(set(selected_pkgs)) # Deduplicate
            
    build_dir = gen.generate(selected_tools, pkg_map, OUTPUT_DIR)
    
    dockerfile_path = Path(build_dir) / "Dockerfile"
    with open(dockerfile_path, 'r') as f:
        content = f.read()
    
    files_list = "\n".join([f"- {f.name}" for f in Path(build_dir).glob("*")])
    return content, f"### Build package generated in `{OUTPUT_DIR}`\n\n**Included files:**\n{files_list}\n\nTo build: `cd {OUTPUT_DIR} && docker build -t my-custom-machine .`"

def _load_profile_data(name, components):
    """Synchronously load a profile JSON and return (core, optional, pkgs, version, status)."""
    path = PROFILE_DIR / f"{name}.json"
    if path.exists():
        try:
            with open(path, "r") as f:
                data = json.load(f)
            core = data.get("core", [])
            optional = data.get("optional", [])
            pkgs = data.get("packages", {})
            version = data.get("version", "legacy")
            status = f"### 📂 Profile '{name}' loaded (v{version})."
            return core, optional, pkgs, version, status
        except Exception:
            pass
    default = [k for k, v in components.items() if v.get("is_default") and k != "ubuntu-base"]
    return default, [], {}, None, ""


def create_ui():
    components = load_components()
    
    # Identify core components and categories
    default_selected = [k for k, v in components.items() if v.get("is_default") and k != "ubuntu-base"]

    # Pre-load default profile synchronously so every widget is correct on first paint
    profiles = get_profiles()
    default_profile = "baseline-workstation" if "baseline-workstation" in profiles else (profiles[0] if profiles else None)
    if default_profile:
        init_core, init_optional, init_pkgs, _, init_status = _load_profile_data(default_profile, components)
    else:
        init_core, init_optional, init_pkgs, _, init_status = default_selected, [], {}, None, ""
    init_merged = list(set(init_core + init_optional))

    # Pre-compute the "clean state" JSON for modification tracking
    sub_sel_comps = [k for k, v in components.items() if "sub_selection" in v]
    def _pkg_val(k):
        cd = init_pkgs.get(k, {})
        if isinstance(cd, list):
            return cd, ""
        defs = [o["name"] for o in components[k]["sub_selection"]["options"] if o.get("selected", True)]
        return cd.get("preset", defs) if k in init_pkgs else defs, cd.get("custom", "")

    simulated_inputs = []
    for k in sub_sel_comps:
        pv, cv = _pkg_val(k)
        simulated_inputs.extend([pv, cv])
    pkg_state = {}
    for i, comp_id in enumerate(sub_sel_comps):
        pv = simulated_inputs[i*2]
        cv = simulated_inputs[i*2+1]
        pkg_state[comp_id] = {"preset": sorted(pv if pv else []), "custom": cv.strip() if cv else ""}
    init_state_json = json.dumps(
        {"core": sorted(init_core), "optional": sorted(init_optional), "packages": pkg_state},
        sort_keys=True
    )

    # Custom CSS
    css = """
    .core-group { background-color: rgba(66, 153, 225, 0.1); border-radius: 8px; padding: 15px; border: 1px solid rgba(66, 153, 225, 0.2); }
    .optional-group { padding: 15px; }
    .package-group { border-left: 4px solid #4299e1; padding-left: 15px; margin-top: 10px; margin-bottom: 20px; }
    .profile-bar { background-color: rgba(0, 0, 0, 0.05); padding: 10px; border-radius: 8px; margin-bottom: 20px; }
    """

    with gr.Blocks(title="FAIR Data Machine Builder", theme=gr.themes.Soft(), css=css) as demo:
        gr.Markdown("# 🤖 FAIR Data Machine Builder")
        gr.Markdown("Configure and generate your optimized FAIRification workstation.")

        with gr.Row(elem_classes=["profile-bar"]):
            with gr.Column(scale=2):
                with gr.Row():
                    profile_selector = gr.Dropdown(label="Stored Profiles", choices=profiles, value=default_profile, scale=2)
                    load_btn = gr.Button("🔄 Reload", scale=1)
                profile_status = gr.Markdown(init_status)
            with gr.Column(scale=2):
                with gr.Row():
                    profile_name = gr.Textbox(label="Save current as...", placeholder="Profile name", scale=2)
                    save_btn = gr.Button("💾 Save Profile", variant="secondary", scale=1)

        with gr.Row():
            with gr.Column(elem_classes=["core-group"]):
                gr.Markdown("### 🏛 Core Components (High-Value Data Defaults)")
                core_choices = sorted([(v["name"], k) for k, v in components.items() if v.get("is_default") and k != "ubuntu-base"], key=lambda x: x[0])
                core_tools = gr.CheckboxGroup(
                    choices=core_choices,
                    label="Included by default",
                    value=init_core
                )
            
            with gr.Column(elem_classes=["optional-group"]):
                gr.Markdown("### 🧩 Optional Add-ons")
                opt_choices = sorted([(v["name"], k) for k, v in components.items() if not v.get("is_default") and k != "ubuntu-base"], key=lambda x: x[0])
                optional_tools = gr.CheckboxGroup(
                    choices=opt_choices,
                    label="Add specialized capabilities",
                    value=init_optional
                )

        with gr.Accordion("📚 Documentation & Homepages", open=False):
            links = []
            for k, v in sorted(components.items(), key=lambda x: x[1]['name']):
                if 'url' in v:
                    links.append(f"[{v['name']}]({v['url']})")
            gr.Markdown(" | ".join(links))

        # State to hold the merged selections
        all_selected = gr.State(value=init_merged)
        current_profile_state = gr.State(value=init_state_json)
        
        package_controls = []
        for k, v in components.items():
            if "sub_selection" in v:
                sub = v["sub_selection"]
                pv, cv = _pkg_val(k)
                with gr.Group(visible=(k in init_merged), elem_classes=["package-group"]) as group:
                    gr.Markdown(f"### 📦 {sub['label']}")
                    with gr.Row():
                        with gr.Column():
                            ctrl = gr.CheckboxGroup(
                                choices=[opt["name"] for opt in sub["options"]],
                                value=pv,
                                label="Preset Packages"
                            )
                        with gr.Column():
                            custom_ctrl = gr.Textbox(
                                label="Additional Packages",
                                value=cv,
                                placeholder="package1, package2, ...",
                                info="Separate by commas or spaces"
                            )
                    package_controls.append((k, group, ctrl, custom_ctrl))

        def handle_tool_change(core, optional):
            merged = list(set(core + optional))
            outputs = [merged]
            # Visibility updates for each package group
            for k, group, ctrl, custom_ctrl in package_controls:
                outputs.append(gr.update(visible=(k in merged)))
            return outputs

        PROFILE_FORMAT_VERSION = "1.0.0"

        def get_current_state_json(core, optional, *pkg_inputs):
            pkg_data = {}
            sub_sel_comps = [k for k, v in components.items() if "sub_selection" in v]
            for i, comp_id in enumerate(sub_sel_comps):
                preset = pkg_inputs[i*2]
                custom = pkg_inputs[i*2 + 1]
                pkg_data[comp_id] = {
                    "preset": sorted(preset if preset else []),
                    "custom": custom.strip() if custom else ""
                }
            
            data = {
                "core": sorted(core if core else []),
                "optional": sorted(optional if optional else []),
                "packages": pkg_data
            }
            return json.dumps(data, sort_keys=True)

        def check_profile_modified(saved_state_json, current_status, core, optional, *pkg_inputs):
            if not saved_state_json or saved_state_json == "{}":
                return gr.update()
            
            current_state = get_current_state_json(core, optional, *pkg_inputs)
            if current_state != saved_state_json:
                return gr.update(value="### ⚠️ Profile modified (unsaved changes).")
            elif "⚠️" in current_status:
                return gr.update(value="### 📂 Profile matches saved state.")
            return gr.update()

        # Profile Actions
        def save_profile_handler(name, core, optional, *pkg_inputs):
            if not name:
                return gr.update(), gr.update(value="### ⚠️ Please provide a name to save the profile"), gr.update()
            
            # Map pkg_inputs back to component IDs
            pkg_data = {}
            sub_sel_comps = [k for k, v in components.items() if "sub_selection" in v]
            for i, comp_id in enumerate(sub_sel_comps):
                pkg_data[comp_id] = {
                    "preset": pkg_inputs[i*2],
                    "custom": pkg_inputs[i*2 + 1]
                }
            
            data = {
                "version": PROFILE_FORMAT_VERSION,
                "core": core,
                "optional": optional,
                "packages": pkg_data
            }
            
            PROFILE_DIR.mkdir(exist_ok=True)
            with open(PROFILE_DIR / f"{name}.json", "w") as f:
                json.dump(data, f, indent=2)
            
            normalized_state = get_current_state_json(core, optional, *pkg_inputs)
            return gr.update(choices=get_profiles(), value=name), gr.update(value=f"### ✅ Profile '{name}' saved."), normalized_state

        def load_profile_handler(name):
            if not name:
                return [gr.update()] * (5 + len(package_controls)*3)

            path = PROFILE_DIR / f"{name}.json"
            if not path.exists():
                return [gr.update()] * (5 + len(package_controls)*3)
            
            try:
                with open(path, "r") as f:
                    data = json.load(f)
            except Exception:
                return [gr.update()] * 4 + [f"### ❌ Error loading profile"] + [gr.update()] * (len(package_controls)*3)
            
            version = data.get("version", "legacy")
            core = data.get("core", [])
            optional = data.get("optional", [])
            merged = list(set(core + optional))
            pkgs = data.get("packages", {})

            simulated_pkg_inputs = []
            for k, group, ctrl, custom_ctrl in package_controls:
                comp_data = pkgs.get(k, {})
                if isinstance(comp_data, list):
                    simulated_pkg_inputs.extend([comp_data, ""])
                else:
                    simulated_pkg_inputs.extend([comp_data.get("preset", []), comp_data.get("custom", "")])

            normalized_state = get_current_state_json(core, optional, *simulated_pkg_inputs)
            
            # Outputs: [current_profile_state, core_tools, optional_tools, all_selected, status, *groups, *preset_ctrls, *custom_ctrls]
            outputs = [normalized_state, core, optional, merged, f"### 📂 Profile '{name}' loaded (v{version})."]
            
            # Add groups visibility
            for k, group, ctrl, custom_ctrl in package_controls:
                outputs.append(gr.update(visible=(k in merged)))
            
            # Add preset controls values
            for k, group, ctrl, custom_ctrl in package_controls:
                comp_data = pkgs.get(k, {})
                if isinstance(comp_data, list):
                    outputs.append(comp_data)
                else:
                    outputs.append(comp_data.get("preset", []))
            
            # Add custom textboxes values
            for k, group, ctrl, custom_ctrl in package_controls:
                comp_data = pkgs.get(k, {})
                if isinstance(comp_data, list):
                    outputs.append("")
                else:
                    outputs.append(comp_data.get("custom", ""))
                
            return outputs

        # Layout for generation results
        generate_btn = gr.Button("🚀 Generate Build Package", variant="primary")
        
        with gr.Row():
            with gr.Column(scale=2):
                output_code = gr.Code(label="Generated Dockerfile", language="dockerfile", interactive=False)
            with gr.Column(scale=1):
                status_msg = gr.Markdown("Ready.")

        # FINAL EVENT REGISTRATION

        # 1. Tool selection changes
        tool_inputs = [core_tools, optional_tools]
        tool_group_outputs = [g for _, g, _, _ in package_controls]
        
        core_tools.change(fn=handle_tool_change, inputs=tool_inputs, outputs=[all_selected] + tool_group_outputs)
        optional_tools.change(fn=handle_tool_change, inputs=tool_inputs, outputs=[all_selected] + tool_group_outputs)

        # 2. Profile management
        all_package_inputs = []
        for _, _, ctrl, custom_ctrl in package_controls:
            all_package_inputs.extend([ctrl, custom_ctrl])

        save_btn.click(
            fn=save_profile_handler,
            inputs=[profile_name, core_tools, optional_tools] + all_package_inputs,
            outputs=[profile_selector, profile_status, current_profile_state]
        )

        load_inputs = [profile_selector]
        load_outputs = [current_profile_state, core_tools, optional_tools, all_selected, profile_status] 
        load_outputs += [g for _, g, _, _ in package_controls] # visibility
        load_outputs += [c for _, _, c, _ in package_controls] # preset checkboxes
        load_outputs += [c for _, _, _, c in package_controls] # custom textboxes

        load_btn.click(fn=load_profile_handler, inputs=load_inputs, outputs=load_outputs)
        profile_selector.change(fn=load_profile_handler, inputs=load_inputs, outputs=load_outputs)

        # 3. Modification Checking
        all_inputs_for_check = [current_profile_state, profile_status, core_tools, optional_tools] + all_package_inputs
        for input_ctrl in [core_tools, optional_tools] + all_package_inputs:
            input_ctrl.change(fn=check_profile_modified, inputs=all_inputs_for_check, outputs=[profile_status])

        # 4. Generation
        generate_btn.click(
            fn=generate_build_package,
            inputs=[all_selected] + all_package_inputs,
            outputs=[output_code, status_msg]
        )


    return demo

if __name__ == "__main__":
    demo = create_ui()
    demo.launch()
