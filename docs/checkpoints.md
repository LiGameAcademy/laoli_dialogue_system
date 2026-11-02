# Checkpoints and state ownership

CheckpointStore reads/writes dictionaries as JSON at an explicit path. It writes a temporary file, verifies its contents, then renames it over the target. Failures report last_error without deliberately deleting the old checkpoint. This does not guarantee power-loss durability.

QuestSnapshot.capture(active, completed) supports collect/kill objectives. Call codec.prepare(data, database) before touching live state. Success exposes independent prepared_quests and prepared_completed; invalid IDs, changed objectives, contradictory flags or progress are rejected.

After validating the complete host snapshot, call QuestManager.install_checkpoint(codec.prepared_quests, codec.prepared_completed). This installs prepared runtime instances and emits quests_loaded. Never pass shared configuration templates.

DialogueHistoryManager.capture_checkpoint() returns portable node_id / speaker / text entries. restore_checkpoint(data) validates the whole array before replacing history and read markers, returning false without mutation for malformed data. Choice details and timestamps are intentionally excluded; full dialogue saves are separate.

The host owns schema versions, story flags, save eligibility, position/actor restoration and compatibility rules. Validate every section before installing any state. Reject unknown versions and inconsistent flags. Block restore during transitions or another restore.

ARPG's three narrative phases are host policy, not plugin checkpoints. These helpers do not save inventory, combat attributes, scene trees or arbitrary Resources.
