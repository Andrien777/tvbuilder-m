extends CircuitComponent
class_name K1533KP7

# ВХОДЫ ДАННЫХ: D0, D1, D2, D3, D4, D5, D6, D7
const DATA_PINS: Array[int] = [4, 3, 2, 1, 15, 14, 13, 12]

# АДРЕСНЫЕ ВХОДЫ: A (S0), B (S1), C (S2)
const ADDR_PINS: Array[int] = [11, 10, 9]

# УПРАВЛЕНИЕ: ~G (Strobe/Enable) - активный низкий
const STROBE_PIN: int = 7

# ВЫХОДЫ: Y (прямой), W (инверсный)
const OUT_Y: int = 5
const OUT_W: int = 6

func _process_signal():
	pin(8).set_low()    # GND
	pin(16).set_high()   # VCC

	# Если на ~G (Strobe) высокий уровень, выходы в "безопасном" состоянии
	if pin(STROBE_PIN).high:
		pin(OUT_Y).set_low()
		pin(OUT_W).set_high()
		return

	# Вычисляем индекс выбранного входа (адрес 0-7)
	var index: int = 0
	if pin(ADDR_PINS[0]).high: index += 1 # A (LSB)
	if pin(ADDR_PINS[1]).high: index += 2 # B
	if pin(ADDR_PINS[2]).high: index += 4 # C (MSB)

	# Читаем состояние выбранного входа
	var selected_value: bool = pin(DATA_PINS[index]).high

	# Устанавливаем выходы
	if selected_value:
		pin(OUT_Y).set_high()
		pin(OUT_W).set_low()
	else:
		pin(OUT_Y).set_low()
		pin(OUT_W).set_high()
