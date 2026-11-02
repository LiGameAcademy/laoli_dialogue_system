# Lao Li's Dialogue System

[简体中文](README_zh-CN.md) · [Documentation](docs/README.md) · [MIT License](LICENSE)

A Godot plugin for Resource/JSON dialogue graphs, quests, read history, variables, and host-driven cutscene playback. Actors, cameras, rewards, and world progression stay in the host game.

**Validated with Godot 4.7.2.** Godot 4.5 compatibility has not been verified. This repository is a plugin directory, not a standalone game project.

## Features

- Dialogue choices, conditions, actions, translation keys, weighted text variants, and themeable UI.
- Quest templates with independent runtime objectives and explicit host event/configuration callbacks.
- History and save services, including portable narrative checkpoint helpers.
- Local `CutscenePlayer`: sequential clips, dialogue requests, waits, correlated callbacks, timeout, skip, cancellation, and failure outcomes.

The four-file cutscene core can run without global dialogue or quest services. The full plugin offers those services without depending on an ARPG implementation.

## Release and branches

[Release v0.1.0](https://github.com/LiGameAcademy/laoli_dialogue_system/releases/tag/v0.1.0) is the first formal release. Install that tag for a reproducible dependency. `master` is the protected stable branch; integration branches are temporary and are removed after their PR is merged.

## Install

From a host Godot project's Git repository:

```sh
git submodule add https://github.com/LiGameAcademy/laoli_dialogue_system.git addons/laoli_dialogue_system
git -C addons/laoli_dialogue_system checkout <validated-tag-or-commit>
git add .gitmodules addons/laoli_dialogue_system
```

Commit the dependency pointer in the host repository. Contributors clone the host with `--recurse-submodules` or run `git submodule update --init --recursive` after checkout. Upgrade explicitly; routine setup should not use `--remote`.

Alternatively, copy the plugin into the same addon path. Enable it in **Project → Project Settings → Plugins**, then reopen Godot so its mutually dependent services load together. Pre-existing host Autoloads are preserved; resolve conflicting names explicitly. See [installation](docs/installation.md).

## Cutscenes

Instance `scenes/cutscene_player/cutscene_player.tscn`, configure a `CutsceneDefinition`, connect `step_requested` and `finished`, then call `play()`. The host starts presentation or dialogue for each request and calls `complete_step(run_id, index)` after the matching operation finishes. WAIT steps advance automatically.

COMPLETED and SKIPPED may commit the intended story result. CANCELED and FAILED restore transient presentation/control without committing that result. The executor does not find actors, manage a global camera, or accept quests. See [the execution contract](docs/cutscenes.md).

## Documentation

- [Installation and host services](docs/installation.md)
- [Dialogue and quests](docs/dialogue_and_quests.md)
- [Cutscene contract](docs/cutscenes.md)
- [Checkpoints and ownership](docs/checkpoints.md)
- [API reference](docs/api.md)
- [Migration](docs/migration.md)
- [中文使用说明](docs/usage_zh-CN.md)

## Validate

With Python 3.10+ and Godot 4.7.2:

```sh
python tools/run_tests.py --godot /path/to/godot
```

Checks run in a disposable host. They cover script import, executor contracts, checkpoint validation/resource isolation, and dialogue/UI compatibility. Concrete lesson plans, recording scripts, and ARPG walkthroughs are maintained outside this repository.
