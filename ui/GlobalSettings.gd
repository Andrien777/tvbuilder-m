extends Node

var LevelHighlight  = false
var doCycles = true
var disableGlobalInput = false
var disableWireConnection = false
var WireSnap = true

var turbo = false

var confirmOnSave = false
var disableAutosave = false

var historyDepth = 200
var ShowSignalsInConnectionTable = false
var CurrentGraphicsMode = LegacyGraphicsMode

enum CURSOR_MODES {NORMAL, SELECTION, CONNECTIVITY_MODE, BUS, SNIPPET}
var CursorMode = CURSOR_MODES.NORMAL

var is_LA_always_on_top = false

func is_normal_mode():
	return CursorMode == CURSOR_MODES.NORMAL

func is_selecting():
	return CursorMode == CURSOR_MODES.SELECTION

func is_connectivity_mode():
	return CursorMode == CURSOR_MODES.CONNECTIVITY_MODE

func is_bus_mode():
	return CursorMode==CURSOR_MODES.BUS

func is_snippet_mode():
	return CursorMode==CURSOR_MODES.SNIPPET
	
	
var PinIndexOffset = 5
var showLastWire = false
var highlightOutputPins = false

var bg_color = Color("999902")
var wire_color = Color(1, 0, 0)
var bg_color_global = Color(0.5, 0.504, 0.004)
var wire_color_global = Color(1, 0, 0)
var highlightedWireColor = Color(0.7,0.7,0.7,1)
var highlightedPinsColor = Color(0.3,0.3,0.3,1)
var highlightedLAPinsColor = Color(0, 0.75, 1, 1)
var highlightedBusColor = Color(0.7,0.7,0.7)
var bus_color_global = Color(1,0.5,0)
var bus_color = Color(1,0.5,0)
var label_color_global = Color(1,1,1)
var label_color = Color(1,1,1)
var recent_projects: Array[String] = []
var useDefaultWireColor = true

var allowSettingsOverride = true

var tps = 200

const ACTION_TO_SAVE = ["delete_component", "confirm", "ZoomUp", "ZoomDown", "abort_wire_creation", "select", "normal", "conn_mode", "bus_mode"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func try_load():
	if FileAccess.file_exists("config.json"):
		var dir = DirAccess.open("")
		dir.copy("config.json", "user://config.json")
		dir.remove("config.json")
	var file = FileAccess.open("user://config.json", FileAccess.READ)
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
				bg_color = bg_color_global
			if parsed.has("WireColor"):
				wire_color_global = Color(parsed["WireColor"])
				wire_color = wire_color_global
			if parsed.has("DefaultWireColor"):
				useDefaultWireColor = parsed["DefaultWireColor"] as bool
			if parsed.has("SettingsOverride"):
				allowSettingsOverride = parsed["SettingsOverride"] as bool
			if parsed.has("HighlightedWireColor"):
				highlightedWireColor = Color(parsed["HighlightedWireColor"])
			if parsed.has("HighlightedPinColor"):
				highlightedPinsColor = Color(parsed["HighlightedPinColor"])
			if parsed.has("HighlightedLAPinColor"):
				highlightedLAPinsColor = Color(parsed["HighlightedLAPinColor"])
			if parsed.has("BusColor"):
				bus_color = Color(parsed["BusColor"])
				bus_color_global = bus_color
			if parsed.has("HighlightedBusColor"):
				highlightedBusColor = Color(parsed["HighlightedBusColor"])
			if parsed.has("tps"):
				tps = parsed["tps"]
				Engine.physics_ticks_per_second = tps
				Engine.max_physics_steps_per_frame = ceili(tps/60)
			if parsed.has("LabelColor"):
				label_color = Color(parsed["LabelColor"])
				label_color_global = label_color
			if parsed.has("is_LA_always_on_top"):
				is_LA_always_on_top = parsed["is_LA_always_on_top"] as bool
			if parsed.has("keybinds"):
				for action in parsed["keybinds"].keys():
					for inp_action in InputMap.get_actions():
						if action==inp_action:
							var keybind_action = inp_action
							var event = InputEventKey.new()
							event.keycode = OS.find_keycode_from_string(parsed["keybinds"][action])
							if not InputMap.action_get_events(keybind_action).is_empty():
								InputMap.action_erase_event(action,InputMap.action_get_events(keybind_action)[-1])
							if event.keycode != KEY_NONE:
								InputMap.action_add_event(keybind_action, event)
			if parsed.has("is_LA_always_on_top"):
				is_LA_always_on_top = parsed["is_LA_always_on_top"] as bool
			if parsed.has("confirmOnSave"):
				confirmOnSave = parsed["confirmOnSave"] as bool
			if parsed.has("recent_projects"):
				for path in parsed["recent_projects"]:
					recent_projects.append(path)
				

func save():
	var file = FileAccess.open("user://config.json", FileAccess.WRITE)
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
	json_object["BusColor"] = bus_color_global.to_html(false)
	json_object["HighlightedBusColor"] = highlightedBusColor.to_html(false)
	json_object["LabelColor"] = label_color_global.to_html(false)
	json_object["tps"] = tps
	json_object["is_LA_always_on_top"] = is_LA_always_on_top as int
	json_object["confirmOnSave"] = confirmOnSave as int
	var keybinds = {}
	for action in ACTION_TO_SAVE:
		var keybind_action
		for inp_action in InputMap.get_actions():
			if action==inp_action:
				keybind_action = inp_action
				if not InputMap.action_get_events(keybind_action).is_empty():
					var event =  InputMap.action_get_events(keybind_action)[-1]
					if event is InputEventKey:
						if event.get_keycode_with_modifiers() == 0:
							keybinds[action] = OS.get_keycode_string(event.get_physical_keycode_with_modifiers())
						else:
							keybinds[action] = OS.get_keycode_string(event.get_keycode_with_modifiers())
					else:
						keybinds[action] = "Не назначено"
				else:
					keybinds[action] = "Не назначено"
	json_object["keybinds"] = keybinds
	json_object["recent_projects"] = recent_projects
		
	file.store_string(JSON.stringify(json_object, "\t"))
	file.close()

func get_object_to_save():
	var json_object = {}
	json_object["version"] = 2
	json_object["BgColor"] = bg_color.to_html(false)
	json_object["WireColor"] = wire_color.to_html(false)
	json_object["DefaultWireColor"] = useDefaultWireColor as int
	json_object["BusColor"] = bus_color.to_html(false)
	json_object["LabelColor"] = label_color.to_html(false)
	return json_object

func add_recent_path(path):
	if recent_projects.size()>=5: #TODO: Make a constant somewhere else
		recent_projects.pop_back()
	if path in recent_projects:
		var index = recent_projects.find(path)
		recent_projects.remove_at(index)
		recent_projects.push_front(path)
	else:
		recent_projects.push_front(path)
		
