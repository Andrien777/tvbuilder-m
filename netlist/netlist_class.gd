extends Node
# Netlist

var nodes: Dictionary # Pin -> NetlistNode

func add_connection(pin1: Pin, pin2: Pin) -> void:
	if pin1 == pin2:
		return
	if pin1 not in nodes.keys():
		var node = NetlistNode.new()
		node.initialize(pin1)
		nodes[pin1] = node
	if pin2 not in nodes.keys():
		var node = NetlistNode.new()
		node.initialize(pin2)
		nodes[pin2] = node
	nodes[pin1].neighbours.append(nodes[pin2])
	nodes[pin2].neighbours.append(nodes[pin1])
	
func delete_connection(pin1, pin2)->void:
	nodes[pin1].neighbours.erase(nodes[pin2])
	nodes[pin2].neighbours.erase(nodes[pin1])
	if nodes[pin1].neighbours.is_empty():
		nodes.erase(pin1)
	if nodes[pin2].neighbours.is_empty():
		nodes.erase(pin2)

func clear():
	nodes.clear()

func propagate_signal() -> void:
	if GlobalSettings.doCycles:
		for ic in ComponentManager.obj_list.values():
			ic._process_signal()
	if nodes.is_empty():
		return
	var visited: Dictionary
	var resolved: Array[NetlistNode]
	var processed_ics: Array[CircuitComponent]
	var late_propagation: Array[NetlistNode]
	var stack: Array[NetlistNode]
	while visited.size() != nodes.size():
		for key in nodes.keys():
			if nodes[key] not in visited:
				stack.push_back(nodes[key])
				break
		while not stack.is_empty():
			var current = stack.back()
			if current in resolved or current in late_propagation:
				stack.pop_back()
				continue
			if current not in visited.keys():
				visited[current] = 1
			else:
				visited[current] += 1
			if visited[current] >= 5:
				if current.pin.input():
					var i = stack.size() - 2
					var found_out = false
					while stack[i] != current:
						if stack[i].pin.output():
							found_out = true
							break
						i -= 1
					if not found_out:
						current.pin.set_z()
						resolved.append(current)
						stack.pop_back()
						continue
				stack.pop_back()
				PopupManager.display_error("Не удалось просчитать данный компонент", "Мы очень пытались. Честно.", current.pin.global_position)
				#print("Could not resolve component:")
				#print(current)
				continue
			if current.pin.output():
				if not current.pin.dependencies.is_empty() and not GlobalSettings.doCycles:
					var dependencies_resolved = true
					for dep in current.pin.dependencies:
						if dep in nodes.keys():
							if nodes[dep] not in resolved:
								dependencies_resolved = false
								stack.push_back(nodes[dep])
							if nodes[dep] in late_propagation:
								late_propagation.append(current)
								stack.pop_back()
								break
					if dependencies_resolved:
						current.pin.parent._process_signal()
						stack.pop_back()
						resolved.append(current)
						for neighbour in current.neighbours:
							if neighbour.pin.output():
								if neighbour in resolved and neighbour.pin.state != current.pin.state:
									if not neighbour.pin.z and not current.pin.z:
										PopupManager.display_error("Соединены два выхода", "Вы делаете что-то странное", current.pin.global_position)
										#print("Two outputs short circuited")
							if neighbour != current:
								stack.push_back(neighbour)
				else:
					if not GlobalSettings.doCycles:
						current.pin.parent._process_signal()
					stack.pop_back()
					resolved.append(current)
					for neighbour in current.neighbours:
						if neighbour.pin.output():
							if neighbour in resolved and neighbour.pin.state != current.pin.state:
								if not neighbour.pin.z and not current.pin.z:
									PopupManager.display_error("Соединены два выхода", "Вы делаете что-то странное", current.pin.global_position)
									#print("Two outputs short circuited")
						if neighbour != current:
							stack.push_back(neighbour)
			elif current.pin.input():
				var counter = 0
				for neighbour in current.neighbours:
					if neighbour.pin.output():
						counter += 1
					elif neighbour.pin.input():
						if neighbour in resolved:
							counter += 1
					if counter >= 2:
						break
				if counter >= 2:
					late_propagation.append(current)
					stack.pop_back()
					for neighbour in current.neighbours:
						if neighbour != current:
							stack.push_back(neighbour)
					continue
				for neighbour in current.neighbours:
					if neighbour in late_propagation:
						late_propagation.append(current)
						break
					if neighbour.pin.output():
						if neighbour in resolved:
							current.pin.state = neighbour.pin.state
							resolved.append(current)
							break
					elif neighbour.pin.input():
						if neighbour in resolved:
							current.pin.state = neighbour.pin.state
							resolved.append(current)
							break
				if current in resolved or current in late_propagation:
					stack.pop_back()
				for neighbour in current.neighbours:
					if neighbour != current:
						stack.push_back(neighbour)
	if not late_propagation.is_empty():
		for pin in late_propagation:
			if pin.pin.output():
				pin.pin.parent._process_signal()
			else:
				var state = pin.neighbours[0].pin.state
				var ok = true
				for neighbour in pin.neighbours:
					if neighbour not in resolved:
						continue
					if neighbour.pin.state != state and neighbour.pin.state != NetConstants.LEVEL.LEVEL_Z:
						if state == NetConstants.LEVEL.LEVEL_Z:
							state = neighbour.pin.state
						else:
							ok = false
				if ok:
					pin.pin.state = state
				else:
					PopupManager.display_error("Короткое замыкание", "В этом месте произошло КЗ", pin.pin.global_position)
					#print("Short circuit")
	for key in nodes.keys():
		if key.direction == NetConstants.DIRECTION.DIRECTION_INPUT_OUTPUT:
			key.parent._process_signal()

func get_json_adjacency():
	var visited: Array[Pin]
	var edges: Array[Dictionary]
	for node in nodes:
		visited.append(node)
		for neighbour in nodes[node].neighbours:
			if neighbour.pin in visited:
				continue
			edges.append({
				"from": {
					"ic": node.parent.id,
					"pin": node.index
				},
				"to": {
					"ic": neighbour.pin.parent.id,
					"pin": neighbour.pin.index
				}
			})
	return edges
