extends CircuitComponent
class_name CONST_1

func _process_signal():
	pin(1).set_high()

func initialize(spec: ComponentSpecification, ic = null)->void:
	super.initialize(spec, ic)
	sprite.texture.normal_texture = preload("res://graphics/Metal_Galvanized_001_normal.jpg")
	sprite.texture.specular_texture = preload("res://graphics/Metal_Galvanized_001_roughness.jpg")

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)

	if(mode == DefaultGraphicsMode):
		self.display_name_label = true
		name_label.visible = true
	elif (mode==LegacyGraphicsMode):
		self.display_name_label = false
		name_label.visible = false
