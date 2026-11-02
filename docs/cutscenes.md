# Cutscene execution contract

CutscenePlayer is a local scene. It does not find actors, control global cameras, start dialogue managers or commit quests. The host supplies a definition, handles step requests and acknowledges the exact run and step.

## Definitions

CutsceneDefinition has a non-empty cutscene_id, typed steps and skippable flag. `validate()` returns an empty string on success or a diagnostic with a zero-based index.

| Kind | Required configuration | Completion |
| --- | --- | --- |
| PLAY_CLIP | Non-empty clip_id; finite positive timeout_seconds | Host callback |
| SHOW_DIALOGUE | Non-empty dialogue_id | Host callback |
| WAIT | Finite non-negative duration_seconds | Executor timer |

Configuration is snapshotted for a run. Editing the original resources cannot change an active step. Match callbacks by IDs, not resource identity.

## Playback

Connect step_requested(run_id, step_index, step), finished(run_id, cutscene_id, outcome), and optionally failed / trace_event. `play(definition)` returns a positive run ID, or -1 when invalid, busy, exiting or outside the tree; inspect last_error for configuration diagnostics.

For PLAY_CLIP, start host presentation and call complete_step(run_id, index) after it finishes. Unknown clips should fail_step with a message. For SHOW_DIALOGUE, start a correlated dialogue session and acknowledge its matching successful completion. A canceled or failed dialogue must not become a successful step.

WAIT needs no host callback. Duplicate, stale and mismatched acknowledgements are ignored. `abort(run_id, message)` handles invalid environments even between steps. Dialogue has no automatic reading timeout; the host owns that policy.

## Outcomes

| Outcome | Host action |
| --- | --- |
| COMPLETED | Restore temporary presentation/control; commit the intended result once |
| SKIPPED | Same intended result when skipping is allowed |
| CANCELED | Restore temporary state without committing |
| FAILED | Restore state and report the failure without committing |

skip(run_id) skips remaining steps without playing them. cancel(run_id, reason) interrupts without committing. Executor tree exit cancels an active run. An accepted run terminates at most once; internal state is cleared before terminal signals.

The host stops its own tweens, closes owned dialogue, restores its previous camera/HUD/input locks and disconnects target observers. Do not let animation duration decide domain results.
