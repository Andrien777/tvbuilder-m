extends Node
class_name I8088
var proc_impl = IProc_8088.new();

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print(proc_impl.get_property_list());
	#print(proc_impl.get_method_list());
	#print(proc_impl.get_meta_list());
	#print(proc_impl.get_signal_list());
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#proc_impl.call();
	pass
