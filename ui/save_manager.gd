extends Node

var last_path: String = ""

var autosave_timer = Timer.new()
var autosave_interval = 60 # seconds

func _on_autosave():
	if last_path != "":
		save(last_path)

func save(path: String) -> void:
	last_path = path
	autosave_timer.stop()
	autosave_timer.start(autosave_interval)
	var json_list_ic: Array
	for ic in ComponentManager.obj_list.values():
		if(!is_instance_valid(ic)):
			PopupManager.display_error("Что-то пошло не так", "Да, это тот самый баг.", Vector2(100,100))
			continue
		json_list_ic.append(ic.to_json_object())
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json.stringify({
		"components": json_list_ic,
		"netlist": NetlistClass.get_json_adjacency(),
		"config": GlobalSettings.get_object_to_save()
	}, "\t"))
	file.close()

func load(scene: Node2D, path: String):
	last_path = path
	autosave_timer.stop()
	autosave_timer.start(autosave_interval)
	ComponentManager.clear()
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	var parsed = json.parse_string(file)
	var parsed_ids = []
	if parsed == null:
		print("error")
		return
	for ic in parsed.components:
		if(ic.id in parsed_ids):
			PopupManager.display_error("Во время открытия произошла ошибка, но файл все равно откроется", "В файле найдены дублированные сохранения. Это известный баг, который мы решаем.", Vector2(100,100))
			continue # TODO: Throw an error
		else:
			parsed_ids.append(ic.id)
		var component: CircuitComponent
		component = load(ComponentManager.ALL_COMPONENTS_LIST[ic.name].logic_class_path).new()
		var spec = ComponentSpecification.new()
		spec.initialize_from_json(ComponentManager.ALL_COMPONENTS_LIST[ic.name].config_path)
		component.initialize(spec, ic)
		ComponentManager.change_id(component, ic.id)
		ComponentManager.last_id = max(ComponentManager.last_id, ic.id) + 1
		scene.add_child(component)
		var pos = ic.position.split(",")
		var x = float(pos[0].replace("(", ""))
		var y = float(pos[1].replace(")", ""))
		component.position = Vector2(x, y)
		#ic_list.append(component) # Component already appends itself during initialization
	for edge in parsed.netlist:
		var from_ic = ComponentManager.get_by_id(edge.from.ic)
		var from_pin: Pin
		for pin in from_ic.pins:
			if pin.index == edge.from.pin:
				from_pin = pin
		if from_pin == null:
			print("error")
			continue
		var to_ic = ComponentManager.get_by_id(edge.to.ic)
		var to_pin: Pin
		for pin in to_ic.pins:
			if pin.index == edge.to.pin:
				to_pin = pin
		if to_pin == null:
			print("error")
			continue
		WireManager._create_wire(from_pin, to_pin)
	if parsed.has("config"):
		if parsed.config.version >= 1:
			if GlobalSettings.allowSettingsOverride:
				GlobalSettings.bg_color = Color(parsed.config["BgColor"])
				get_node("/root/RootNode/GridSprite").modulate = GlobalSettings.bg_color
				GlobalSettings.wire_color = Color(parsed.config["WireColor"])
				GlobalSettings.useDefaultWireColor = parsed.config["DefaultWireColor"] as bool
				for wire in WireManager.wires:
					wire.change_color()
		
func _init():
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave)
