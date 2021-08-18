'''Test code for feature in iiCalc.
Parses text in a shell-like way and converts it into python function calls.
Works with arguments.
'''

import ast


class ShellParser:
	'''Parses text in a shell-like way and converts it into python function calls.
	Works with arguments.
	'''
	def __init__(self, text):
		self.text = text.split()
		self.pointer = 2 # skip the first two which are the module and method
		self.args = []
		self.kwargs = {}

	def module_name(self):
		'''Returns the name of the module being called.'''
		return self.text[0]

	def method_name(self):
		'''Returns the method name being called.'''
		return self.text[1]

	def current_token(self):
		'''Returns the current token.'''
		try:
			return self.text[self.pointer]
		except IndexError:
			return ''

	def current_token_name(self):
		'''Return the current token name (without ``--``).'''
		return self.current_token().lstrip('-')

	def next_token(self):
		'''Returns next token in list'''
		try:
			return self.text[self.pointer + 1]
		except IndexError:
			return ''

	def is_flag(self):
		'''Check if the current token is a flag argument or not.'''
		return self.is_keyword_argument() and (self.next_token().startswith('--') or not self.next_token())

	def is_keyword_argument(self):
		'''Check if the current token is a keywork argument. i.e. starts with --'''
		return self.text[self.pointer].startswith('--')

	def incr_token_pointer(self, amount=1):
		'''Increment the token pointer by ``amount``. Defaults to 1'''
		self.pointer += amount

	def eval_arguments(self):
		'''Use ast.literal_eval to safely eval things like integers and booleans'''
		for index, item in enumerate(self.args):
			try:
				self.args[index] = ast.literal_eval(item)
			except ValueError:
				pass

		for item in self.kwargs:
			try:
				self.kwargs[item] = ast.literal_eval(self.kwargs[item])
			except ValueError:
				pass

		return self

	def parse_args(self):
		'''Iterate through all tokens and sort them out into args or kwargs'''
		while self.current_token():
			if self.is_flag():
				self.kwargs[self.current_token_name()] = 'True'
				self.incr_token_pointer()

			elif self.is_keyword_argument():
				self.kwargs[self.current_token_name()] = self.next_token()
				self.incr_token_pointer(2)

			else:
				self.args.append(self.current_token_name())
				self.incr_token_pointer()

		return self


while True:
	test = ShellParser(input('> ')).parse_args().eval_arguments()

	print(f'{test.module_name()}.{test.method_name()}({test.args}, {test.kwargs})')
