extends Button
var is_listening = false
var mouse_bindable = false
var keyboard_bindable = true
var action_name = "delete_component"
var action = null
var current_event = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for action in InputMap.get_actions():
		if action==action_name:
			self.action = action
			if not InputMap.action_get_events(action).is_empty():
				var event =  InputMap.action_get_events(action)[0]
				current_event = event
				self.text = event.as_text()
			else:
				self.text = "Не назначено"
	if self.text=="":
		self.text = "Нет назначения с таким именем"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event:InputEvent):
	if is_listening:
		if event is InputEventKey and keyboard_bindable or event is InputEventMouseButton and mouse_bindable:
			is_listening = false
			self.text = event.as_text()
			bind_to_action(event)

func _on_pressed() -> void:
	self.text = "Нажмите клавишу"
	is_listening = true

func bind_to_action(event:InputEvent):
	if action:
		if current_event:
			InputMap.action_erase_event(action,current_event)
		InputMap.action_add_event(action, event)
