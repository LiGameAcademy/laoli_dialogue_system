extends RefCounted
## Validates the portable, minimal dialogue history used by narrative checkpoints.

static func validate(data: Variant) -> bool:
	if not data is Array:
		return false
	var ids: Array[String] = []
	for value: Variant in data:
		if not value is Dictionary:
			return false
		var entry: Dictionary = value as Dictionary
		for key: String in ["node_id", "speaker", "text"]:
			if not entry.get(key) is String:
				return false
		if String(entry["node_id"]).is_empty() or ids.has(String(entry["node_id"])):
			return false
		ids.append(String(entry["node_id"]))
	return true
