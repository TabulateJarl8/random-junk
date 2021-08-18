import ast

def eval_all_args(args):
	print(args)
	if isinstance(args, dict):
		for item in args:
			try:
				args[item] = ast.literal_eval(args[item])
			except ValueError:
				pass

	elif isinstance(args, list):
		for index, item in enumerate(args):
			try:
				args[index] = ast.literal_eval(item)
			except ValueError:
				pass

	return args

class ShellParser:
	def __init__(self, text):
		self.text = text.split()
		self.pointer = 0
		self.args = []
		self.kwargs = {}

	def current_token(self):
		try:
			return self.text[self.pointer]
		except IndexError:
			return ''

	def current_token_name(self):
		return self.current_token().lstrip('-')

	def next_token(self):
		try:
			return self.text[self.pointer + 1]
		except IndexError:
			return ''

	def is_flag(self):
		return self.text[self.pointer].startwith('--') and (self.next_token().startwith('--') or not self.next_token())

	def incr_token_pointer(self):
		self.pointer += 1


def parse(text):
	parsed = text.split()

	module_name = parsed.pop(0)

	method_name = parsed.pop(0)

	args = []
	kwargs = {}

	try:
		tok = parsed.pop(0)
	except IndexError:
		tok = ''

	while tok:

		try:
			next_tok = parsed.pop(0)
		except IndexError:
			next_tok = ''

		print(tok, next_tok)

		if tok.startswith('--'):

			if next_tok and next_tok.startswith('--'):
				# tok is a flag instead of kwargs
				kwargs[tok[2:]] = 'True'
			else:
				kwargs[tok[2:]] = next_tok
		else:
			args.append(tok)

		tok = next_tok

	args = eval_all_args(args)
	kwargs = eval_all_args(kwargs)

	print(f'{module_name}.{method_name}({args}, {kwargs})')

while True:
	parse(input('> '))
