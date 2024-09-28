extends StaticBody2D
class_name Wire

var first_object
var second_object
var line
const pin_offset = 30
func initialize(first_object:Node2D, second_object:Node2D)->void:
	line.clear_points()

	line.add_point(first_object.global_position)
	line.add_point(first_object.global_position+get_pin_offset(first_object))
	line.add_point(Vector2((first_object.global_position+get_pin_offset(first_object)).x,(second_object.global_position+get_pin_offset(second_object)).y))
	line.add_point(second_object.global_position+get_pin_offset(second_object))
	line.add_point(second_object.global_position)
	self.first_object = first_object
	self.second_object = second_object

func _init()->void:
	line = Line2D.new()
	#line.add_point(Vector2(0,0))
	#line.add_point(Vector2(500,500))
	line.width = 2
	line.antialiased = true
	add_child(line)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _mouse_enter() -> void:
	print("mouse on ", self)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# TODO: Render only if position of start|end nodes changed
	if first_object!=null and second_object!=null: # TODO: Notify WireManager about missing object
		line.set_point_position(0, first_object.global_position)
		line.set_point_position(1, first_object.global_position+get_pin_offset(first_object))
		line.set_point_position(2,Vector2(line.get_point_position(1).x,line.get_point_position(3).y))
		line.set_point_position(line.get_point_count()-2,second_object.global_position+get_pin_offset(second_object))
		line.set_point_position(line.get_point_count()-1,second_object.global_position)
	else:
		WireManager._delete_wire(self)
		
		
func get_pin_offset(pin:Node2D):
	if(not pin is Pin): # Wire technically traces two Node2Ds, not two pins
		return Vector2.ZERO
	match pin.ic_position:
		"TOP":
			return Vector2.UP*pin_offset
		"BOTTOM":
			return Vector2.DOWN*pin_offset
		"LEFT":
			return Vector2.LEFT*pin_offset
		"RIGHT":
			return Vector2.RIGHT*pin_offset
		
