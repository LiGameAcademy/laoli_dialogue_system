# Dialogue and quests

DialogueNode resources define IDs, translation keys, optional weighted text variants, actions, choices and a next-node ID. DialogueOption resources carry their own conditions and actions. JSON files are parsed into the same graph.

Load with `DialogueManager.load_dialogue_file(path, merge)`. Merging replaces duplicate IDs. Start ordinary interaction with `start_dialogue(id)` or reserve a correlated session with `start_dialogue_session(id)`. Supply the initiator explicitly for actions and conditions.

The supplied UI uses session-aware advancement and choices. Custom UIs should use `advance_dialogue_session(id)` and `make_session_choice(id, data)` so stale callbacks cannot advance a later conversation. Cancellation differs from completion.

Register GameAction and GameCondition instances through `register_action` and `register_condition`. Their `has_registered_*` queries help hosts avoid duplicate setup. VariableManager handles substitutions; localization tables belong to the host.

Quest resources are read-only templates. Accepting a quest creates runtime objective progress. Register the host game-event signal, database-membership callback and resource lookup callback before using quests.

Statuses are CAN_ACCEPT, IN_PROGRESS, READY_TO_TURN_IN and FINISHED. Completing objectives does not automatically hand in a quest; call `turn_in_quest(id)` after host interaction checks. Rewards and world progression remain host policy.

Subscribe to quest_accepted, quest_updated, quest_completed, quest_turned_in and quests_loaded to refresh presentation. Restoring a prepared checkpoint emits quests_loaded instead of replaying accept/reward actions.
