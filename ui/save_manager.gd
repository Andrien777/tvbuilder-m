extends Node

var ic_list: Array[CircuitComponent]

static var all_components: Dictionary

func save(path: String) -> void:
	var json_list_ic: Array
	for ic in ic_list:
		if(!is_instance_valid(ic)):
			PopupManager.display_error("Что-то пошло не так", "Да, это тот самый баг.", Vector2(100,100))
			continue
		json_list_ic.append(ic.to_json_object())
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json.stringify({
		"components": json_list_ic,
		"netlist": NetlistClass.get_json_adjacency()
	}, "\t"))
	file.close()

func get_component_by_id(id: int) -> CircuitComponent: #null if not found
	for ic in ic_list:
		if ic.id == id:
			return ic
	return null

func load(scene: Node2D, path: String):
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
		component = load(all_components[ic.name].logic_class_path).new()
		var spec = ComponentSpecification.new()
		spec.initialize_from_json(all_components[ic.name].config_path)
		component.initialize(spec)
		component.id = ic.id
		scene.add_child(component)
		var pos = ic.position.split(",")
		var x = float(pos[0].replace("(", ""))
		var y = float(pos[1].replace(")", ""))
		component.position = Vector2(x, y)
		#ic_list.append(component) # Component already appends itself during initialization
	for edge in parsed.netlist:
		var from_ic = get_component_by_id(edge.from.ic)
		var from_pin: Pin
		for pin in from_ic.pins:
			if pin.index == edge.from.pin:
				from_pin = pin
		if from_pin == null:
			print("error")
			continue
		var to_ic = get_component_by_id(edge.to.ic)
		var to_pin: Pin
		for pin in to_ic.pins:
			if pin.index == edge.to.pin:
				to_pin = pin
		if to_pin == null:
			print("error")
			continue
		WireManager._create_wire(from_pin, to_pin)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var json = JSON.new()
	var file = FileAccess.open("res://components/all_components.json", FileAccess.READ).get_as_text()
	all_components = json.parse_string(file)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
