extends Button


@onready var signals_h_split_container = get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/SignalsHSplitContainer")

func _on_pressed() -> void:
	signals_h_split_container.clear_signal_values()
