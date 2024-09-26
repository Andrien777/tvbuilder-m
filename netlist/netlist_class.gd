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
	
func propagate_signal() -> void:
	if nodes.is_empty():
		return
	var visited: Dictionary
	var resolved: Array[NetlistNode]
	var late_propagation: Array[NetlistNode]
	var stack: Array[NetlistNode]
	while visited.size() != nodes.size():
		for key in nodes.keys():
			if nodes[key] not in visited:
				stack.push_back(nodes[key])
				break
		while not stack.is_empty():
			var current = stack.back()
			if current in resolved:
				stack.pop_back()
				continue
			if current not in visited.keys():
				visited[current] = 1
			else:
				visited[current] += 1
			if visited[current] >= 5:
				stack.pop_back()
				print("Could not resolve component:")
				print(current)
				continue # TODO: add notification
			match current.pin.direction:
					NetConstants.DIRECTION.DIRECTION_OUTPUT:
						if not current.pin.dependencies.is_empty():
							var dependencies_resolved = true
							for dep in current.pin.dependencies:
								if dep in nodes.keys():
									if nodes[dep] not in resolved:
										dependencies_resolved = false
										stack.push_back(nodes[dep])
							if dependencies_resolved:
								current.pin.parent._process_signal()
								stack.pop_back()
								resolved.append(current)
								for neighbour in current.neighbours:
									if neighbour.pin.direction == NetConstants.DIRECTION.DIRECTION_OUTPUT:
										if neighbour in resolved and neighbour.pin.state != current.pin.state:
											print("Two outputs short circuited")
									if neighbour != current:
										stack.push_back(neighbour)
						else:
							current.pin.parent._process_signal()
							stack.pop_back()
							resolved.append(current)
							for neighbour in current.neighbours:
								if neighbour.pin.direction == NetConstants.DIRECTION.DIRECTION_OUTPUT:
									if neighbour in resolved and neighbour.pin.state != current.pin.state:
										print("Two outputs short circuited")
								if neighbour != current:
									stack.push_back(neighbour)
					NetConstants.DIRECTION.DIRECTION_INPUT:
						var counter = 0
						for neighbour in current.neighbours:
							if neighbour.pin.direction == NetConstants.DIRECTION.DIRECTION_OUTPUT:
								counter += 1
							elif neighbour.pin.direction == NetConstants.DIRECTION.DIRECTION_INPUT:
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
							if neighbour.pin.direction == NetConstants.DIRECTION.DIRECTION_OUTPUT:
								if neighbour in resolved:
									current.pin.state = neighbour.pin.state
									resolved.append(current)
									break
							elif neighbour.pin.direction == NetConstants.DIRECTION.DIRECTION_INPUT:
								if neighbour in resolved:
									current.pin.state = neighbour.pin.state
									resolved.append(current)
									break
						if current in resolved:
							stack.pop_back()
						for neighbour in current.neighbours:
							if neighbour != current:
								stack.push_back(neighbour)
	if not late_propagation.is_empty():
		for pin in late_propagation:
			var state = pin.neighbours[0].pin.state
			var ok = true
			for neighbour in pin.neighbours:
				if neighbour not in resolved:
					continue
				if neighbour.pin.state != state:
					if state == NetConstants.LEVEL.LEVEL_Z:
						state = neighbour.pin.state
					else:
						ok = false
			if ok:
				pin.pin.state = state
			else:
				print("Short circuit")
