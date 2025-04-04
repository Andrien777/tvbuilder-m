extends PanelContainer

var snippets = []
var selected_snippet

func _ready() -> void:
	if OS.has_feature("web"):
		visible = false
		return
	find_snippets()
	update_list()

func _on_add_snippet_button_pressed() -> void:
	if CopyBuffer.buffer.is_empty():
		InfoManager.write_error("Для создания сниппета необходимо что-либо скопировать")
		return
	%GlobalInput.ask_for_input("Название сниппета", add_snippet)

func add_snippet(snippet_name: String):
	if snippet_name.is_valid_filename() and not snippet_name.is_empty() and not "./snippets/" + snippet_name + ".snippet" in snippets:
		var path = "./snippets/" + snippet_name + ".snippet"
		SaveManager.save_snippet(path)
		snippets.append(path)
		update_list()
	else:
		InfoManager.write_error("Недопустимое название сниппета")
		return

func find_snippets():
	snippets.clear()
	var dir = DirAccess.open("")
	if not dir.dir_exists("./snippets"):
		snippets = []
		dir.make_dir("./snippets")
		return
	dir.change_dir("./snippets")
	for file in dir.get_files():
		if file.get_extension() == "snippet":
			snippets.append("./snippets/" + file)

func update_list():
	$VBoxContainer/ScrollContainer/VBoxContainer/ItemList.clear()
	if not snippets.is_empty():
		for snippet in snippets:
			$VBoxContainer/ScrollContainer/VBoxContainer/ItemList.add_item(snippet.get_file().get_basename())

func _on_item_list_item_activated(index: int) -> void:
	GlobalSettings.CursorMode = GlobalSettings.CURSOR_MODES.SNIPPET
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)
	selected_snippet = snippets[index]

func place_snippet(pos):
	GlobalSettings.CursorMode = GlobalSettings.CURSOR_MODES.NORMAL
	$VBoxContainer/ScrollContainer/VBoxContainer/ItemList.deselect_all()
	if selected_snippet != "":
		SaveManager.load_snippet(pos, get_tree().current_scene, selected_snippet)
		selected_snippet = ""
	else:
		InfoManager.write_error("Недопустимое название сниппета")
		return

func toggle_visibility():
	if OS.has_feature("web"):
		visible = false
		InfoManager.write_warning("Сниппеты не поддерживаются в веб-версии")
		return
	visible = !visible

func delete_selected_snippet():
	if selected_snippet != "":
		var dir = DirAccess.open("")
		var err = dir.remove(selected_snippet)
		if err != 0:
			InfoManager.write_error("Ошибка при удалении сниппета: код %d" % [err])
			find_snippets()
			update_list()
			return
		snippets.erase(selected_snippet)
		selected_snippet = ""
		update_list()

var previousGlobalInputState
func _on_item_list_mouse_entered() -> void:
	previousGlobalInputState = GlobalSettings.disableGlobalInput
	GlobalSettings.disableGlobalInput = true


func _on_item_list_mouse_exited() -> void:
	GlobalSettings.disableGlobalInput = previousGlobalInputState and GlobalSettings.disableGlobalInput

func _on_item_list_item_selected(index: int) -> void:
	selected_snippet = snippets[index]
