extends Node

var last_path: String = ""

var autosave_timer = Timer.new()
var autosave_interval = 60 # seconds
var do_not_save_ids: Array[int] = []

func _on_autosave():
	if last_path != "" and not OS.has_feature("web"):
		save(last_path)

func save(path: String) -> void:
	last_path = path
	autosave_timer.stop()
	autosave_timer.start(autosave_interval)
	var json_list_ic: Array
	for ic in ComponentManager.obj_list.values():
		if(!is_instance_valid(ic)):
			InfoManager.write_error("При сохранении был найден неверный объект. Данный объект не будет сохранён.")
			continue
		if ic.id in do_not_save_ids:
			continue
		json_list_ic.append(ic.to_json_object())
	var json = JSON.new()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(json.stringify({
			"components": json_list_ic,
			"netlist": NetlistClass.get_json_adjacency(),
			"config": GlobalSettings.get_object_to_save(),
			"buses": WireManager.buses_to_json()
		}, "\t").to_utf8_buffer(), path.get_file(), "application/json")
	else:
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(json.stringify({
			"components": json_list_ic,
			"netlist": NetlistClass.get_json_adjacency(),
			"config": GlobalSettings.get_object_to_save(),
			"buses": WireManager.buses_to_json()
		}, "\t"))
		file.close()
	get_window().title = "TVBuilder - " + path.get_file().get_basename()
	InfoManager.write_info("Файл %s сохранён" % [path])


func load(scene: Node2D, path: String):
	last_path = path
	autosave_timer.stop()
	autosave_timer.start(autosave_interval)
	ComponentManager.clear()
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	parse_save_str(scene, file, path)
	
func parse_save_str(scene: Node2D, file: String, path="LoadedProject.json"):
	var json = JSON.new()
	var parsed = json.parse_string(file)
	var parsed_ids = []
	if parsed == null:
		InfoManager.write_error("Не удалось считать открываемый файл")
		return
	for ic in parsed.components:
		if(ic.id in parsed_ids):
			InfoManager.write_error("В файле найден дубликат элемента. Файл все равно откроется, но его содержимое может не отображаться корректно")
			continue
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
	if parsed.has("buses"):
		load_buses(parsed.buses, scene)
	for edge in parsed.netlist:
		var from_ic = ComponentManager.get_by_id(edge.from.ic)
		var from_pin: Pin
		if from_ic == null:
			InfoManager.write_error("Ошибка. Не удалось найти компонент с id = %d при загрузке провода" % [edge.from.ic])
			continue
		for pin in from_ic.pins:
			if pin.index == edge.from.pin:
				from_pin = pin
		if from_pin == null:
			InfoManager.write_error("Ошибка. Не удалось найти поле 'from', id = %d при загрузке провода" % [edge.from.ic])
			continue
		var to_ic = ComponentManager.get_by_id(edge.to.ic)
		var to_pin: Pin
		if to_ic == null:
			InfoManager.write_error("Ошибка. Не удалось найти компонент с id = %d при загрузке провода" % [edge.to.ic])
			continue
		for pin in to_ic.pins:
			if pin.index == edge.to.pin:
				to_pin = pin
		if to_pin == null:
			InfoManager.write_error("Ошибка. Не удалось найти поле 'to', id = %d при загрузке провода" % [edge.to.ic])
			continue
		if "wire" in edge:
			if "control_points" in edge.wire:
				var points = []
				for p in edge.wire.control_points:
					var pos = p.split(",")
					var x = float(pos[0].replace("(", ""))
					var y = float(pos[1].replace(")", ""))
					points.append(Vector2(x,y))
				WireManager._create_wire(from_pin, to_pin, points)
			else:
				WireManager._create_wire(from_pin, to_pin)
		else:
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
		if parsed.config.version >= 2:
			if GlobalSettings.allowSettingsOverride:
				GlobalSettings.bus_color = Color(parsed.config["BusColor"])
				GlobalSettings.label_color = Color(parsed.config["LabelColor"])
				for bus in WireManager.buses:
					bus.change_color()
				for component in ComponentManager.obj_list.values():
					component.change_color()
	get_window().title = "TVBuilder - " + path.get_file().get_basename()
	InfoManager.write_info("Файл %s загружен" % [path])
		
func _init():
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave)

func do_not_save(id:int):
	if id not in do_not_save_ids:
		do_not_save_ids.append(id)
		
func load_buses(json, scene):
	for _bus in json:
		var bus = Bus.new()
		var control_points: Array[Vector2] = []
		for p in _bus.control_points:
			control_points.append(parse_Vector2(p))
		bus.initialize(control_points)
		ComponentManager.change_id(bus.component, _bus.id)
		ComponentManager.last_id = max(ComponentManager.last_id, _bus.id) + 1
		do_not_save(_bus.id)
		WireManager.register_bus(bus)
		# DO NOT ADD BUS TO THE SCENE. IT IS HANDLED BY THE WIRE MANAGER
		#scene.add_child(bus)
		for conn in _bus.connections:
			for pin in conn.pins:
				bus.add_connection(conn.name, pin.index, parse_Vector2(pin.position))

func parse_Vector2(s:String):
	var pos = s.split(",")
	var x = float(pos[0].replace("(", ""))
	var y = float(pos[1].replace(")", ""))
	return Vector2(x, y)
