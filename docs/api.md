# Host API reference

| Type / service | Public entry points |
| --- | --- |
| DialogueManager | load_dialogue_file(path, merge), unload_dialogue_file(path), clear_all_dialogues() |
| Initiator | set_initiator(actor), clear_initiator(actor) |
| Sessions | start_dialogue_session(id), is_session_current(id), advance_dialogue_session(id), make_session_choice(id, data), cancel_dialogue_session(id) |
| Extensions | register_action(id, action), register_condition(id, condition), has_registered_action(id), has_registered_condition(id) |
| Quest setup | register_game_event_signal(signal), register_quest_database_provider(callable), register_quest_resource_getter(callable) |
| Quest operations | accept_quest(resource), accept_quest_by_id(id), get_quest_status(id), turn_in_quest(id), install_checkpoint(quests, completed) |
| DialogueHistoryManager | get_history(), is_node_read(id), clear_history(), capture_checkpoint(), restore_checkpoint(data) |
| VariableManager | set_variable(name, value), batch_update_variables(data), register_variable_provider(callable) |
| CutsceneDefinition | validate() -> String |
| CutscenePlayer | play(definition), complete_step(run, index), fail_step(run, index, message), abort(run, message), skip(run), cancel(run, reason), is_playing() |
| CheckpointStore | new(path), save_snapshot(data), load_snapshot(), last_error |
| QuestSnapshot | capture(active, completed), prepare(data, database), prepared_quests, prepared_completed, last_error |

For sequencing and failure semantics, see [cutscenes](cutscenes.md) and [checkpoints](checkpoints.md). Legacy start_dialogue and player getters remain supported; new integrations should provide initiators and correlate asynchronous operations by session ID.
