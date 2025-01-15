extends StaticBody2D
class_name Bus
var control_points = []
var line
var is_mouse_over = false
func _init()->void:
	line = Line2D.new()
	#line.add_point(Vector2(0,0))
	#line.add_point(Vector2(500,500))
	line.width = 2
	line.antialiased = true
	add_child(line)
	self.input_pickable = true
	

func initialize(control_points):
	for p in control_points:
		line.add_point(p)

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass # Replace with function body.


func _mouse_enter() -> void:
	self.line.width = 4
	self.modulate=Color(0.7,0.7,0.7,1)
	is_mouse_over = true
func _mouse_exit() -> void:
	self.line.width = 2
	self.modulate=Color(1,1,1,1)
	is_mouse_over = false
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
