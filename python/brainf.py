"""Probably working BrainF interpreter
Uses 8-bit cells.
"""

import argparse
import re


class Cells:
	"""BrainF Cells Class
	"""

	def __init__(self):
		self.cells = [0]
		self.pointer = 0
		self._instruction_mapping = {
			'+': self.increment,
			'-': self.decrement,
			'<': self.seek_left,
			'>': self.seek_right,
			',': self.take_user_input,
			'.': self.print_current_cell
		}

	def seek_left(self):
		"""Move pointer to the left by one
		"""
		if self.pointer == 0:
			# beginning of cells, insert another
			self.cells.insert(0, 0)
		else:
			self.pointer -= 1

	def seek_right(self):
		"""Move pointer to the right by one
		"""
		if self.pointer == len(self.cells) - 1:
			# end of cells, append another
			self.cells.append(0)

		self.pointer += 1

	def increment(self):
		"""Increment current cell by one
		"""
		if self.cells[self.pointer] != 255:
			self.cells[self.pointer] += 1
		else:
			# current cell is 255, overflow to 0 since we have 8-bit cells
			self.cells[self.pointer] = 0

	def decrement(self):
		"""Decrement current cell by one
		"""
		if self.cells[self.pointer]:
			self.cells[self.pointer] -= 1
		else:
			# current cell is 0, underflow to 255 since we have 8-bit cells
			self.cells[self.pointer] = 255

	def print_current_cell(self):
		"""Converts the current cell's value to ASCII and then prints it
		"""
		print(chr(self.cells[self.pointer]), end='', flush=True)

	def take_user_input(self):
		"""Read first byte of user input into current cell
		"""
		# only read first byte of character, even if its more than 1 byte
		input_as_bytes = input()[0].encode('utf-8')[0]
		self.cells[self.pointer] = input_as_bytes

	def current_cell_is_zero(self):
		"""Returns True is current cell is equal to zero, else False
		"""
		return not self.cells[self.pointer]

	def run_instruction_set(self, instructions):
		"""Run a set of BrainF instructions passed as an iterable
		"""
		for char in instructions:
			try:
				# print(instructions, self._instruction_mapping[char])
				self._instruction_mapping[char]()
			except KeyError as exc:
				raise SyntaxError(f'Unexpected token: {char}') from exc

	def __repr__(self):
		return f'Cells(cells={self.cells}, pointer={self.pointer})'


class BrainF:
	def __init__(self, code, cells):
		self.code = code
		self.cells = cells
		self.loop_count = 0

		self.first = ''
		self.loop = ''
		self.second = ''
		self.loop_code = None
		self.second_code = None

		self.parse_code()

	def parse_code(self):
		for char in self.code:
			# order of checking here is extremely important
			if self.loop_count == 0 and self.loop:
				# we've already gone through the loop, append the rest to second
				self.second += char
			elif char == ']':
				# attempt to close a loop if we haven't already been through
				self.loop_count -= 1
			elif char == '[':
				self.loop_count += 1
			elif self.loop_count == 0 and not self.loop:
				# not in a loop yet, append to first
				self.first += char

			if self.loop_count > 0:
				# in loop currently; append to loop unless its the [ which opens the loop
				if not (char == '[' and self.loop_count == 1):
					self.loop += char

		if self.loop:
			self.loop_code = BrainF(self.loop, self.cells)
		if self.second:
			self.second_code = BrainF(self.second, self.cells)

	def run(self):
		self.cells.run_instruction_set(self.first)
		if self.loop_code is not None:
			while not self.cells.current_cell_is_zero():
				self.loop_code.run()
		if self.second_code is not None:
			self.second_code.run()


	def __repr__(self):
		return f'BrainF(first={self.first!r}, loop={self.loop!r}, second={self.second!r})'


def main(brainf_text):
	"""Main entrypoint. Accepts brainf_text as a string
	"""
	cells = Cells()
	BrainF(brainf_text, cells).run()


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='BrainF Interpreter written in Python')
	parser.add_argument('in_file', type=argparse.FileType('r', encoding='UTF-8'), help='Input file')

	args = parser.parse_args()

	brainf = re.sub(r'[^<>+\-,.[\]]', '', args.in_file.read())

	main(brainf)
