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
func display(heading:String, description:String, position:Vector2, color:Color):

	self.description.text = description
	self.heading.text = heading
	

	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(self,"modulate",color,0.3).set_trans(Tween.TRANS_CIRC)
	if modulate[3]<0.1:
		self.size = Vector2(max(len(description)*12,len(heading)*12),self.size[1])
		self.position = position + Vector2(40,0)
	else:
		tween.tween_property(self,"position", position + Vector2(40,0),0.3).set_trans(Tween.TRANS_CIRC)
		tween.tween_property(self,"size",Vector2(max(len(description)*12,len(heading)*12),self.size[1]),0.1).set_trans(Tween.TRANS_CIRC)
		#self.size = Vector2(max(len(description)*12,len(heading)*12),self.size[1])


func hide_popup():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self,"modulate",Color(1,1,1,0.0),1).set_trans(Tween.TRANS_CIRC)

	
