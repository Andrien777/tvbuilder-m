extends Node

var LevelHighlight  = false
var doCycles = true
var disableGlobalInput = false

var historyDepth = 200

var CurrentGraphicsMode = LegacyGraphicsMode

var showLastWire = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func try_load():
	var file = FileAccess.open("config.json", FileAccess.READ)
	if file != null:
		var json_string = file.get_as_text()
		file.close()
		var parsed: Dictionary = JSON.parse_string(json_string)
		if parsed != null:
			if parsed.has("LevelHighlight"):
				LevelHighlight = parsed["LevelHighlight"] as bool
			if parsed.has("AltAlgo"):
				doCycles = not (parsed["AltAlgo"] as bool)
			if parsed.has("HistoryDepth"):
				historyDepth = parsed["HistoryDepth"]
			if parsed.has("GraphicsMode"):
				match parsed["GraphicsMode"]:
					"LegacyGraphicsMode":
						CurrentGraphicsMode = LegacyGraphicsMode
					"DefaultGraphicsMode":
						CurrentGraphicsMode = DefaultGraphicsMode
			if parsed.has("ShowLastWire"):
				showLastWire = parsed["ShowLastWire"] as bool
				

func save():
	var file = FileAccess.open("config.json", FileAccess.WRITE)
	var json_object = {}
	json_object["LevelHighlight"] = LevelHighlight as int
	json_object["AltAlgo"] = (not doCycles) as int
	json_object["HistoryDepth"] = historyDepth
	match CurrentGraphicsMode:
		LegacyGraphicsMode:
			json_object["GraphicsMode"] = "LegacyGraphicsMode"
		DefaultGraphicsMode:
			json_object["GraphicsMode"] = "DefaultGraphicsMode"
	json_object["ShowLastWire"] = showLastWire as int
	file.store_string(JSON.stringify(json_object, "\t"))
	file.close()
