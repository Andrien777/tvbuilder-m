extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_recent_projects_button_pressed() -> void:
	for i in range(GlobalSettings.recent_projects.size()):
		self.set_item_text(i, GlobalSettings.recent_projects[i])
		self.set_item_disabled(i, false)
	for i in range(GlobalSettings.recent_projects.size(), 5 - GlobalSettings.recent_projects.size()):
		self.set_item_text(i, "Нет проекта")
		self.set_item_disabled(i, true)
	self.visible = true
	self.position = get_node("../FileButton").position + Vector2(get_node("/root/RootNode").get_window().position) + Vector2(-2, 36)


func _on_index_pressed(index: int) -> void:
	SaveManager.load(get_tree().current_scene, GlobalSettings.recent_projects[index])
	self.visible = false
