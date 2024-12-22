extends CircuitComponent
class_name ALS324A
#static var lut = {
	#[1,1,1,1,1,1,0]:0,
	#[0,1,1,0,0,0,0]:1,
	#[1,1,0,1,1,0,1]:2,
	#[1,1,1,1,0,0,1]:3,
	#[0,1,1,0,0,1,1]:4,
	#[0,1,1,1,0,1,1]:5,
	#[0,0,1,1,1,1,1]:6,
	#[1,1,1,0,0,0,0]:7,
	#[1,1,1,1,1,1,1]:8,
	#[1,1,1,0,0,1,1]:9,
	#[0,0,0,1,1,0,1]:10,
	#[0,0,1,1,0,0,1]:11,
	#[0,1,0,0,0,1,1]:12,
	#[1,0,0,1,0,1,1]:13,
	#[0,0,0,1,1,1,1]:14,
	#[0,0,0,0,0,0,0]:15
	#}
#var label
var bottom_left_sprite = null
var bottom_left_texture = preload("res://graphics/legacy/ic/7segment/BOTTOM_LEFT.png")
var bottom_right_texture = preload("res://graphics/legacy/ic/7segment/BOTTOM_RIGHT.png")
var bottom_center_texture = preload("res://graphics/legacy/ic/7segment/BOTTOM_CENTER.png")
var top_right_texture = preload("res://graphics/legacy/ic/7segment/TOP_RIGHT.png")
var top_left_texture = preload("res://graphics/legacy/ic/7segment/TOP_LEFT.png")
var top_center_texture = preload("res://graphics/legacy/ic/7segment/TOP_CENTER.png")
var mid_center_texture = preload("res://graphics/legacy/ic/7segment/MID_CENTER.png")
var textures = [top_center_texture,top_right_texture,bottom_right_texture,bottom_center_texture,bottom_left_texture,top_left_texture,mid_center_texture]
var sprites = []
func _init():
	#label = Label.new()
	#label.position = self.position + Vector2(-20,-20)
	#label.z_index = 2
	#label.text = "Z"
	#add_child(label)
	
	for texture in textures:
		sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.z_index = 1
		sprite.visible=false
		sprite.centered = false
		sprites.append(sprite)
		add_child(sprite)
	#bottom_left_sprite = Sprite2D.new()
	#bottom_left_sprite.texture = bottom_left_texture
	#bottom_left_sprite.z_index = 1
	#bottom_left_sprite.global_position = Vector2(50,50)
	#add_child(bottom_left_sprite)

func initialize(spec: ComponentSpecification, ic = null)->void:
	self.display_name_label = false
	super.initialize(spec, ic)

func _process(delta: float) -> void:
	super._process(delta)
	var inputs = [pin(14).high as int,pin(13).high as int,pin(8).high as int,pin(7).high as int,pin(6).high as int ,pin(1).high as int ,pin(2).high as int]
	for i in range(inputs.size()):
		sprites[i].visible = (inputs[i] == 1)

func _process_signal():
	pin(16).set_high()
	pin(4).set_low()
	pin(12).set_low()
	
