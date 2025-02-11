extends CircuitComponent
class_name Resistor

func _init():
	display_name_label = false

func initialize(spec: ComponentSpecification, ic = null)->void:
	super.initialize(spec, ic)
	NetlistClass.add_connection(pin(1), pin(2))

func _process_signal():
	if pin(1).high:
		pin(2).set_z()
	if pin(2).high:
		pin(1).set_z()

func fully_delete():
	NetlistClass.delete_connection(pin(1), pin(2))
	super.fully_delete()
