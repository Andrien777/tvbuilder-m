extends BoxContainer

var textfield : LineEdit
var callback: Callable
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textfield = $LineEdit


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _input(event):
	if event.is_action_pressed("confirm"):
		if(callback):
			callback.call(textfield.text)
		self.hide()
		GlobalSettings.disableGlobalInput = false
		GlobalSettings.disableWireConnection = false
	
func ask_for_input(placeholder:String, callback:Callable, clear_content=true, text = ""):
	if(clear_content):
		textfield.text = ""
	if text!="":
		textfield.text = text
	GlobalSettings.disableGlobalInput = true
	GlobalSettings.disableWireConnection = true
	self.show()
	self.callback = callback
	
	textfield.grab_focus()
	textfield.placeholder_text = placeholder


	
