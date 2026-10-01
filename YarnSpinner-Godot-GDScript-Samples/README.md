# Yarn Spinner for Godot Samples (GDScript)

Each sample has a page in the [Yarn Spinner for Godot (GDScript) docs](https://yarnspinner.dev/docs/godot/gdscript/07-samples/) that explains how it works.

## Requirements

- Godot 4.6 or later (the standard build)
- The Yarn Spinner for Godot (GDScript) addon, installed at `addons/yarn_spinner`

## Setup

The addon isn't included in this repository. On a fresh clone the `addons/` folder is empty, so:

1. [Install Yarn Spinner](https://yarnspinner.dev/install/).
2. Copy its `addons/yarn_spinner/` folder into this project's `addons/` folder, or make a symbolic link to it. You should end up with `addons/yarn_spinner/plugin.cfg` next to this project's `project.godot`.
3. Open the project in Godot. If the Yarn Spinner plugin isn't on, turn it on in **Project > Project Settings > Plugins**.

The first import compiles every sample's Yarn Project, which takes a momment. The addon has a compiler built in.

If Godot shows "Load failed due to missing dependencies" for `res://addons/yarn_spinner/...` paths, or scripts fail with `Could not find type "YarnDialogueRunner"`, the addon isn't where the project expects it. Check that you copied the inner `addons/yarn_spinner` folder, not the whole repository. A path like `addons/YarnSpinner-Godot-GDScript/addons/yarn_spinner` won't work. The same error dialog may list a `.yarnproject` file too. That file is fine, and loads once the addon is in place!

## Samples

Each folder under `samples/` is a sample with a scene you can run. Running the whole project starts Yarn Basics. The Samples browser in the editor's Yarn Spinner tab lists them in this order.

The samples will change during Early Access. They don't work with Yarn Spinner for Godot (C#), which comes with its own samples.

- [`welcome`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/02-welcome/): Capsley gives a short talk introducing the samples, with slides on a projector screen
- [`yarn_basics`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/01-yarn-basics/): a guided tour of the Yarn language, covering lines, variables, if statements, options, Commands, Functions, markup, jumps, detours and `once` (the project's main scene)
- [`simple_3d`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/16-simple-3d/): the smallest 3D setup, with one character saying one line
- [`feature_tour`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/03-feature-tour/): a 3D building where each room shows a different Yarn Spinner feature
- [`commands_and_functions`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/04-commands-and-functions/): custom Commands and Functions that let Yarn control the game and read its state
- [`instance_commands`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/05-instance-commands/): Commands that target a specific node in the scene
- [`inline_events`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/06-inline-events/): movement and emotions triggered from inside a line
- [`node_internals`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/15-node-internals/): looking through a node's Commands before it runs, to load the assets they need ahead of time
- [`replacement_markup`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/13-replacement-markup/): markup that replaces text with icons and styled text
- [`themed_line_presenter`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/14-themed-line-presenter/): restyling the built-in Line Presenter
- [`options_that_timeout`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/12-options-that-timeout/): options that are picked for the player if they take too long
- [`phone_chat`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/11-phone-chat/): a conversation told as text messages in chat bubbles
- [`background-chatter`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/10-background-chatter/): conversations between characters in the background, shown above their heads
- [`voice_over`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/17-voice-over/): a recorded voice clip for each line, in several languages
- [`voice_over_3d`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/18-voice-over-3d/): voice-over in a 3D scene, with lip sync
- [`basic-saliency`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/07-basic-saliency/): characters choosing what to say with node groups and line groups
- [`custom-saliency`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/08-custom-saliency/): writing your own saliency strategy
- [`advanced_saliency`](https://yarnspinner.dev/docs/godot/gdscript/07-samples/09-advanced-saliency/): choosing a scene's cast, room and scenario, with storylets deciding what everyone says
- `shared`: art, scenes, UI and scripts used by several samples

## Licence

These samples are released under the Yarn Spinner Public Licence (YSPL). See [LICENSE.md](LICENSE.md).
