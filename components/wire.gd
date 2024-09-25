extends StaticBody2D
class_name Wire

var first_object
var second_object
var line

func initialize(first_object:Node2D, second_object:Node2D)->void:
	line.add_point(first_object.global_position)
	#line.add_point(Vector2(first_object.global_position.x,second_object.global_position.y))
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# TODO: Render only if position of start|end nodes changed
	if first_object!=null and second_object!=null: # TODO: Notify WireManager about missing object
		line.set_point_position(0, first_object.global_position)
		#line.set_point_position(1,Vector2(first_object.global_position.x,second_object.global_position.y))
		line.set_point_position(line.get_point_count()-1,second_object.global_position)
	else:
		WireManager._delete_wire(self)
