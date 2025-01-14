extends ColorPickerButton
var background_sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_sprite = get_node('/root/RootNode/GridSprite')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	background_sprite.modulate = color
