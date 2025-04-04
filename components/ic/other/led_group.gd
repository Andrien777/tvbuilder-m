extends CircuitComponent
class_name LEDGroup
var texture_on = preload("res://graphics/legacy/led/ld_up_green.png")
var texture_off = preload("res://graphics/legacy/led/ld_down_green.png")
var default_texture  = preload("res://components/ic/ic2.svg")
var sprite_arr = []
var light_arr = []
func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false
	
	for i in range(8):
		var led_sprite = Sprite2D.new()
		sprite_arr.append(led_sprite)
		var light = PointLight2D.new()
		light.texture = preload("res://graphics/point_light.webp")
		light.color = Color(10, 100, 50)
		light.texture_scale = 2.5
		light.energy = 0.002
		light.shadow_enabled = true
		light.height = 10
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		light.enabled = false
		light_arr.append(light)
	super.initialize(spec)
	occluder.occluder_light_mask = 2
	for i in range(8):
		var led_sprite = sprite_arr[i]
		led_sprite.position = Vector2(sprite.texture.get_size().y / 2 + i * sprite.texture.get_size().y, sprite.texture.get_size().y / 2)
		light_arr[i].position = Vector2(sprite.texture.get_size().y / 2 + i * sprite.texture.get_size().y, sprite.texture.get_size().y / 2)
		if(GlobalSettings.CurrentGraphicsMode==DefaultGraphicsMode):
			led_sprite.texture = ic_texture
			led_sprite.modulate = Color(0, 100, 0, 0.2)
		else:
			led_sprite.texture = texture_off
		add_child(light_arr[i])
		add_child(led_sprite)

func _process(delta: float)->void:
	super._process(delta)
	for i in range(8):
		if pins[i].high:
			set_on(i)
		else:
			set_off(i)
		
		
func set_on(i):
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		sprite_arr[i].set_texture(texture_on)
	else:
		sprite_arr[i].modulate = Color(0, 100, 0, 1)
	light_arr[i].enabled = true
		
func set_off(i):
	if GlobalSettings.CurrentGraphicsMode==LegacyGraphicsMode:
		sprite_arr[i].set_texture(texture_off)
	else:
		sprite_arr[i].modulate = Color(0, 0, 0, 1)
	light_arr[i].enabled = false

func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	if(mode == DefaultGraphicsMode):
		for i in range(8):
			sprite_arr[i].texture = ic_texture
			sprite_arr[i].modulate = Color(0, 100, 0, 0.2)
	else:
		for i in range(8):
			sprite.modulate = Color(1,1,1,1)
			sprite_arr[i].modulate = Color(1, 1, 1, 1)
			sprite_arr[i].texture = texture_off
	for i in range(8):
		light_arr[i].position = Vector2(sprite.texture.get_size().y / 2 + i * sprite.texture.get_size().y, sprite.texture.get_size().y / 2)
