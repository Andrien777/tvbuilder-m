extends Node

enum Radix { HEXADECIMAL = 16, DECIMAL = 10, OCTAL = 8, BINARY = 2, BINARY_DECIMAL = 8421 }

func radix_to_string(radix: Radix):
	match radix:
		Radix.HEXADECIMAL:
			return "Шестнадцатеричное"
		Radix.DECIMAL:
			return "Десятичное"
		Radix.OCTAL:
			return "Восьмеричное"
		Radix.BINARY:
			return "Двоичное"
		Radix.BINARY_DECIMAL:
			return "Двочно-десятичное (8421)"
		_:
			return "Странное"
