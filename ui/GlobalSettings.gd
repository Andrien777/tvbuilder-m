extends Node

var LevelHighlight  = false
var doCycles = true
var disableGlobalInput = false

var WireSnap = true

var turbo = false


var historyDepth = 200
var ShowSignalsInConnectionTable = false
var CurrentGraphicsMode = LegacyGraphicsMode

enum CURSOR_MODES {NORMAL, SELECTION, CONNECTIVITY_MODE}
var CursorMode = CURSOR_MODES.NORMAL

func is_normal_mode():
	return CursorMode == CURSOR_MODES.NORMAL

func is_selecting():
	return CursorMode == CURSOR_MODES.SELECTION

func is_connectivity_mode():
	return CursorMode == CURSOR_MODES.CONNECTIVITY_MODE

var PinIndexOffset = 5


var showLastWire = false
var highlightOutputPins = false

var bg_color = Color(0.5, 0.504, 0.004)
var wire_color = Color(1, 0, 0)
var bg_color_global = Color(0.5, 0.504, 0.004)
var wire_color_global = Color(1, 0, 0)
var highlightedWireColor = Color(0.7,0.7,0.7,1)
var highlightedPinsColor = Color(0.3,0.3,0.3,1)
var highlightedLAPinsColor = Color(0, 0.75, 1, 1)
var useDefaultWireColor = true

var allowSettingsOverride = true


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
			if parsed.has("BgColor"):
				bg_color_global = Color(parsed["BgColor"])
			if parsed.has("WireColor"):
				wire_color_global = Color(parsed["WireColor"])
			if parsed.has("DefaultWireColor"):
				useDefaultWireColor = parsed["DefaultWireColor"] as bool
			if parsed.has("SettingsOverride"):
				allowSettingsOverride = parsed["SettingsOverride"] as bool
			if parsed.has("HighlightedWireColor"):
				wire_color = Color(parsed["HighlightedWireColor"])
			if parsed.has("HighlightedPinColor"):
				wire_color = Color(parsed["HighlightedPinColor"])
			if parsed.has("HighlightedLAPinColor"):
				wire_color = Color(parsed["HighlightedLAPinColor"])
				

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
	json_object["BgColor"] = bg_color_global.to_html(false)
	json_object["WireColor"] = wire_color_global.to_html(false)
	json_object["DefaultWireColor"] = useDefaultWireColor as int
	json_object["SettingsOverride"] = allowSettingsOverride as int
	json_object["HighlightedWireColor"] = highlightedWireColor.to_html(false)
	json_object["HighlightedPinColor"] = highlightedPinsColor.to_html(false)
	json_object["HighlightedLAPinColor"] = highlightedLAPinsColor.to_html(false)
	file.store_string(JSON.stringify(json_object, "\t"))
	file.close()

func get_object_to_save():
	var json_object = {}
	json_object["version"] = 1
	json_object["BgColor"] = bg_color.to_html(false)
	json_object["WireColor"] = wire_color.to_html(false)
	json_object["DefaultWireColor"] = useDefaultWireColor as int
	return json_object
