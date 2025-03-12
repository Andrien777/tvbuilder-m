extends CircuitComponent
class_name LED_red
var led_sprite: Sprite2D
var light: PointLight2D
var texture_on = preload("res://graphics/legacy/led/ld_up_red.png")
var texture_off = preload("res://graphics/legacy/led/ld_down_red.png")
var default_texture  = preload("res://components/ic/ic2.svg")
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false
	light = PointLight2D.new()
	light.texture = preload("res://graphics/point_light.webp")
	light.color = Color(100, 0, 0)
	light.texture_scale = 2.5
	light.energy = 0.006
	light.light_mask = 1
	light.shadow_enabled = true
	light.height = 10
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.enabled = false
	led_sprite = Sprite2D.new()
	super.initialize(spec)
	sprite.texture.normal_texture = preload("res://graphics/metal_normal.jpg")
	sprite.texture.specular_texture = preload("res://graphics/Metal_Galvanized_001_roughness.jpg")
	occluder.occluder_light_mask = 2
	light.position = hitbox.shape.size / 2
	led_sprite.position = sprite.texture.get_size() / 2
	if(GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
		led_sprite.texture = ic_texture
		led_sprite.modulate = Color(100, 0, 0, 0.2)
	else:
		led_sprite.texture = texture_off
	readable_name = "Светодиод (кр.)"
	add_child(led_sprite)
	add_child(light)

func _process(delta: float)->void:
	super._process(delta)
	if pins[0].state == NetConstants.LEVEL.LEVEL_HIGH:
		set_on()
	else:
		set_off()
		
		
func set_on():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		led_sprite.set_texture(texture_on)
	else:
		sprite.modulate = Color(100, 0, 0, 1)
	light.enabled = true
		
func set_off():
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		led_sprite.set_texture(texture_off)
	else:
		sprite.modulate = Color(0, 0, 0, 1)
	light.enabled = false

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	if(mode == DefaultGraphicsMode):
		led_sprite.texture = ic_texture
		led_sprite.modulate = Color(100, 0, 0, 0.2)
	else:
		sprite.modulate = Color(1,1,1,1)
		led_sprite.modulate = Color(1, 1, 1, 1)
		led_sprite.texture = texture_off
	light.position = hitbox.shape.size / 2

	
