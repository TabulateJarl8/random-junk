from dataclasses import dataclass
import enum

class Type(enum.Enum):
	STR = "char"
	INT = "int"

class VariableUse(enum.Enum):
	ASSIGN = "assign"
	REFERENCE = "reference"

class Comparison(enum.Enum):
	EQUAL = "equal"
	GREATER = "greater"
	LESS = "less"

@dataclass
class Variable:
	name: str
	value: str
	type: Type
	use: VariableUse

@dataclass
class String:
	value: str

@dataclass
class Int:
	value: int

OBJECT = Variable | String | Int

@dataclass
class Conditional:
	left: OBJECT
	right: OBJECT
	comparison: Comparison

@dataclass
class Print:
	value: OBJECT