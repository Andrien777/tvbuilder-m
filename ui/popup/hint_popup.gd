extends Panel
class_name HintPopup
var heading
var description

func _init()->void:
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	self.size = Vector2(150,100)
	heading = Label.new()
	heading.position = Vector2(20,20)
	description = Label.new()
	description.position = Vector2(20,40)
	#heading.text = ""
	add_child(description)
	add_child(heading)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var style:StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color =  Color.DIM_GRAY
	style.bg_color.a = 0.9
	style.set_corner_radius_all(15)
	add_theme_stylebox_override("panel", style)




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
var tween
func display(heading:String, description:String, position:Vector2):
	
	self.description.text = description
	self.heading.text = heading
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self,"modulate",Color(1,1,1,0.9),0.3).set_trans(Tween.TRANS_CIRC)
	
	if modulate[3]<0.1:
		self.position = position + Vector2(40,0)
	else:
		tween.tween_property(self,"position", position + Vector2(40,0),0.3).set_trans(Tween.TRANS_CIRC)

func hide_popup():
	pass
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self,"modulate",Color(1,1,1,0.0),1).set_trans(Tween.TRANS_CIRC)

	
