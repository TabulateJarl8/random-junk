from tokens import *
import shlex

def is_integer(n):
	try:
		float(n)
	except ValueError:
		return False
	else:
		return float(n).is_integer()

def lex(text):
	instructions = []
	variable_names = []
	
	# what following will become the worse parser known to man
	sentences = text.strip().rstrip('.').split('. ')
	for sentence in sentences:
		words = iter(shlex.split(sentence.strip()))
		for word in words:
			# determine instruction
			if word == 'set':
				name = next(words)
				next(words)
				next(words)
				value = next(words)

				type = Type.STR
				if is_integer(value):
					type = Type.INT
					
				variable_names.append(name)
				instructions.append(
					Variable(
						name,
						value,
						type,
						VariableUse.ASSIGN
					)

				)
			if word == 'if':
				left = next(words)
				next(words)
				# WARNING: this doesn't support any comparison longer than two words
				comparison_str = next(words)

				if comparison_str == "equal":
					comparison = Comparison.EQUAL
				elif comparison_str == "greater":
					comparison = Comparison.GREATER
				elif comparison_str == "less":
					comparison = Comparison.LESS

				next(words)
				right = next(words)
				next(words)

				if is_integer(left):
					left_object = Int(left)
				elif variable_names.count(left) != 0:
					left_object = Variable(left, "", None, VariableUse.REFERENCE)
				else:
					left_object = String(left)

				if is_integer(right):
					right_object = Int(right)
				elif variable_names.count(right) != 0:
					right_object = Variable(right, "", None, VariableUse.REFERENCE)
				else:
					right_object = String(right)

				instructions.append(
					Conditional(
						left_object,
						right_object,
						comparison
					)
				)

			if word == 'say':
				remainder = list(words)
				instructions.append(
					Print(
						' '.join(remainder)
					)
				)
	return instructions