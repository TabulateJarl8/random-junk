from tokens import *

def transpile(tokens):
	c_code = ['#include <stdio.h>', 'int main() {']
	inside_condition = 0
	for inst in tokens:
		if isinstance(inst, Variable):
			if inst.use == VariableUse.ASSIGN:
				inst_value = inst.value
				if inst.type == Type.STR:
					inst_value = f'"{inst.value}"'
				c_code.append(f'{inst.type.value} {inst.name}{"[]" if inst.type == Type.STR else ""}={inst_value};')
		
		elif isinstance(inst, Print):
			c_code.append(f'printf("{inst.value}");')

		elif isinstance(inst, Conditional):
			tmp_code = 'if ('
			if isinstance(inst.left, String):
				tmp_code += f'"{inst.left.value}" '
			elif isinstance(inst.left, Int):
				tmp_code += inst.left.value + ' '
			elif isinstance(inst.left, Variable):
				tmp_code += inst.left.name + ' '

			if inst.comparison == Comparison.EQUAL:
				tmp_code += '== '
			elif inst.comparison == Comparison.GREATER:
				tmp_code += '> '
			elif inst.comparison == Comparison.LESS:
				tmp_code += '< '

			if isinstance(inst.right, String):
				tmp_code += f'"{inst.right.value}" '
			elif isinstance(inst.right, Int):
				tmp_code += inst.right.value + ' '
			elif isinstance(inst.right, Variable):
				tmp_code += inst.right.name + ' '

			tmp_code += '){'

			c_code.append(tmp_code)
			inside_condition = 2

		if inside_condition == 1:
			c_code[-1] = c_code[-1] + '}'

		inside_condition -= 1

	c_code.extend(['return 0;', '}'])

	return c_code

