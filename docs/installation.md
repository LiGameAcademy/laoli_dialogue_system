# Installation and host services

Mount this repository root at `res://addons/laoli_dialogue_system/`. It contains `plugin.cfg`, `scripts/`, `scenes/`, and `ui/`; do not nest another addons directory inside it.

Use a pinned submodule commit. Publish and validate plugin changes before changing a host's gitlink. Avoid maintaining a second embedded implementation.

The full plugin registers DialogueHistoryManager, VariableManager, QuestManager and DialogueManager. Enable the plugin and reopen Godot. Disable removes only settings installed and still owned by the plugin. Existing host Autoloads are preserved; resolve same-name/different-path conflicts before using the full plugin.

Instance `ui/dialogue_ui.tscn` in the host UI. Configure custom fonts and sound as host assets. Defaults use a system font and require no bundled third-party audio.

Register quest dependencies during host initialization:

```gdscript
QuestManager.register_game_event_signal(GameState.game_event_occurred)
QuestManager.register_quest_database_provider(
    func(id: String) -> bool: return GameState.quest_database.has(id))
QuestManager.register_quest_resource_getter(
    func(id: String) -> Quest: return GameState.quest_database.get(id) as Quest)
```

GameState here is a host example, not a plugin dependency. Call `DialogueManager.set_initiator(actor)` before interaction, and `clear_initiator(actor)` when the host exits. Register custom actions and conditions explicitly.

For cutscene-only use, retain the relative paths of these four files: `scripts/core/cutscene/cutscene_step.gd`, `cutscene_definition.gd`, and `scenes/cutscene_player/cutscene_player.gd` / `.tscn`. Do not enable the full plugin for this standalone core.

For installation failures, check nesting, conflicting Autoload names, Godot version, and whether the project was reopened after service registration. Inspect script errors; editor startup alone does not prove successful installation.
