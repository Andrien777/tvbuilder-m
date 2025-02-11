extends Button


@onready var simulation_ad: AcceptDialog = get_node("../../../SimulationAcceptDialog")

func _ready() -> void:
	custom_minimum_size = Vector2(size.y, size.y)


func _on_pressed() -> void:
	simulation_ad.show()
