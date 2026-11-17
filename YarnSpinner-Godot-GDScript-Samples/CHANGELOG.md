# Yarn Spinner Samples for Godot (GDScript) — Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

### Changed

### Fixed

### Removed

## [3.3.1] - 2026-11-17

### Early Access 3.3.1

- New **Custom Actions** sample!Its Yarn Project generates a variables class, and the inventory Commands and Functions take the generated `FoodType` enum. Bring Hungry Henry the fruit he asks for: a Function that waits for the player to pick an item from their inventory, and a Command the player can skip.
- `SimpleCharacter.move_to()` takes an optional `YarnCancellationToken`. When the token is cancelled, the character jumps to the end of the walk.
- Talking to something whose dialogue finishes straight away, like a node that only runs a Command, no longer leaves the player unable to move.
- The shared option scene, and the Voice Over sample's, now have a `RichTextLabel` for the option's text, so options show their markup formatting.
- Custom Actions passes the picked fruit's value straight to `<<remove_inventory_item>>`, and no longer has the `get_foodtype_name()` Function, the same as the Yarn Spinner for Unity sample.
- Every sample's Yarn Project is now file version 5.
- The shared `DialogueInteractable` and the Background Chatter sample now wait for dialogue with `await dialogue_runner.run_dialogue()`.
- In Inline Events, `<<move>>` and the inline `[move]` marker now take the cancellation token, so the player can skip the walk.
- Inline Events and Node Internals add their commands straight away in `_ready()`.
- In Commands and Functions, the effect and health commands take numbers as `float` and `int` parameters.
- Commands that make the dialogue wait now use `await` and return nothing, in place of returning a `Signal`, in Commands and Functions, Instance Commands, Voice Over and Node Internals. This is the same shape as the async Commands in the Yarn Spinner for Unity samples.
- Options in Themed Line Presenter and Phone Chat now show their markup formatting. Their option buttons extend `YarnOptionButton` and have a `RichTextLabel` for the text.
