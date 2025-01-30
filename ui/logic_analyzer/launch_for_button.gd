extends Button



@onready var launch_for_ad: AcceptDialog = get_node("../../../LaunchForAcceptDialog")

func _ready() -> void:
	custom_minimum_size = Vector2(size.y, size.y)


func _on_pressed() -> void:
	launch_for_ad.show()
