# Yarn Spinner for Godot Samples (GDScript)

Sample projects demonstrating Yarn Spinner for Godot, as a standalone Godot 4.6 project.

## Requirements

- Godot 4.6 or later (the standard build)
- The Yarn Spinner for Godot (GDScript) addon, installed at `addons/yarn_spinner`
- `ysc`, the Yarn Spinner compiler: `dotnet tool install YarnSpinner.Console --global --version 3.2.2`

## Setup

The addon is not included in this repository. On a fresh clone the `addons/` folder is empty, and nothing will load until the addon is in place.

1. Clone or download [YarnSpinner-Godot-GDScript](https://github.com/YarnSpinnerTool/YarnSpinner-Godot-GDScript).
2. Copy its `addons/yarn_spinner/` folder into this project's `addons/` directory, or symlink it from your checkout. The plugin config should end up at `addons/yarn_spinner/plugin.cfg`, alongside this project's `project.godot`.
3. Open the project in Godot and enable the Yarn Spinner plugin under **Project > Project Settings > Plugins** if it isn't already on. The first import compiles each sample's Yarn project with `ysc`, which takes a moment.

If Godot shows "Load failed due to missing dependencies" for `res://addons/yarn_spinner/...` paths, or scripts fail with `Could not find type "YarnDialogueRunner"`, the addon isn't where the project expects it. Check that you copied the inner `addons/yarn_spinner` folder rather than the whole repository; `addons/YarnSpinner-Godot-GDScript/addons/yarn_spinner` won't resolve. A `.yarnproject` file listed in the same error dialog is a side effect: the file is present, but the code that loads it is part of the addon.

## Samples

Each folder under `samples/` is a self-contained sample within Godot; open its scene and run it, or run the project to start with the Yarn basics sample.

The samples we ship are subject to change at all times, especially during the Alpha/Beta period. These samples will not work with Yarn Spinner for Godot (C#), and that version of Yarn Spinner currently ships with its own samples.

- `yarn_basics`: introduction to Yarn scripts, lines, and options (default main scene)
- `welcome`: welcome scene
- `feature_tour`: tour of the main features
- `commands_and_functions`: custom commands and functions
- `instance_commands`: commands on node instances
- `inline_events`: inline events in lines
- `basic-saliency` / `custom-saliency`: salient content selection
- `advanced_saliency`: a staged scene whose cast, room, and scenario all drive saliency
- `background-chatter`: ambient background dialogue
- `phone_chat`: dialogue styled as a phone messaging conversation
- `options_that_timeout`: timed option selection
- `replacement_markup`: replacement markup
- `themed_line_presenter`: customising the line presenter
- `node_internals`: inspecting node internals
- `simple_3d`: dialogue in a 3D scene
- `voice_over` / `voice_over_3d`: voice-over playback
- `shared`: assets shared between samples

## Licence

See [LICENSE.md](LICENSE.md).
