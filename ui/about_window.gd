extends Window


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("web"):
		size.y = 700


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_requested() -> void:
	hide()

func _on_open_request():
	visible=true
