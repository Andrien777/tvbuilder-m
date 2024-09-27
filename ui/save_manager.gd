extends Node

static var ic_list: Array[CircuitComponent]

func save() -> void:
	var json_list_ic: Array
	for ic in ic_list:
		json_list_ic.append(ic.to_json_object())
	var json = JSON.new()
	var file = FileAccess.open("res://save.json", FileAccess.WRITE)
	file.store_string(json.stringify({
		"components": json_list_ic,
		"netlist": NetlistClass.get_json_adjacency()
	}, "\t"))
	file.close()

func load(scene: Node2D):
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
