extends ColorPickerButton
var background_sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_sprite = get_node('/root/RootNode/GridSprite')
	color = Color(background_sprite.modulate, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_color_changed(color: Color) -> void:
	background_sprite.modulate = Color(color, 0.7)
	GlobalSettings.bg_color = color
	GlobalSettings.bg_color_global = color

func reset_color():
	color = Color("999902", 1)
	background_sprite.modulate = Color(color, 0.7)
	GlobalSettings.bg_color_global = Color(color, 0.7)
	GlobalSettings.bg_color = Color(color, 0.7)
