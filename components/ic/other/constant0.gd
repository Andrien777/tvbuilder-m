extends CircuitComponent
class_name CONST_0

func _process_signal():
	pin(1).set_low()

func initialize(spec: ComponentSpecification, ic = null)->void:
	super.initialize(spec, ic)
	sprite.texture.normal_texture = null
	sprite.texture.specular_texture = null
	sprite.material.shader = preload("res://shaders/glare.gdshader")

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)

	if(mode == DefaultGraphicsMode):
		self.display_name_label = true
		name_label.visible = true
	elif (mode==LegacyGraphicsMode):
		self.display_name_label = false
		name_label.visible = false
