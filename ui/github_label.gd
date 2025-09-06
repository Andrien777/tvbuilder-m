extends Label

func _ready() -> void:
	if OS.has_feature("web"):
		visible = true
