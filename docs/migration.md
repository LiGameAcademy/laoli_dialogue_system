# Migrating embedded copies

1. Archive the existing host and its embedded plugin. Keep recorded-course tags unchanged.
2. Move shared fixes into the plugin repository; retain actors, rooms, cameras, rewards and story definitions in the host.
3. Replace the tracked embedded directory with a submodule at the same addon path. Pin a published, validated commit.
4. Use the plugin services, wiring host event/configuration callbacks explicitly. Remove duplicate host managers after migration and reopen Godot.
5. Replace the course-only CutsceneDefinition.validata() spelling with validate(). Validate and play the selected definition consistently for alternate sequences.
6. Replace DialogueManager.transcript with DialogueHistoryManager.capture_checkpoint() / restore_checkpoint(). The minimal history schema remains node_id / speaker / text.
7. Run plugin contracts and the host integration suite against the actual gitlink. Verify scene references, signals, checkpoint restore and instance isolation.

Upgrades change host gitlinks after testing. Do not move published course tags to migrated commits. Plugin internals have one source of truth; game-specific behavior stays in the host.
