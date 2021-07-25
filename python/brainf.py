"""Sort of working BrainF interpreter
Doesn't work with nested loops.
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


def main(brainf_text):
	"""Main entrypoint. Accepts brainf_text as a string
	"""
	cells = Cells()
	loop_buffer = []
	in_loop = False

	for char in brainf_text:
		if char == '[':
			# start of loop
			in_loop = True

		elif char == ']':
			# end of loop, run instructions until current cell is zero

			while in_loop:
				cells.run_instruction_set(loop_buffer)

				# set to false here so that the loop always gets ran once
				if cells.current_cell_is_zero():
					in_loop = False

			loop_buffer = []

		elif in_loop:
			loop_buffer.append(char)

		else:
			cells.run_instruction_set(char)


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='BrainF Interpreter written in Python')
	parser.add_argument('in_file', type=argparse.FileType('r', encoding='UTF-8'), help='Input file')

	args = parser.parse_args()

	brainf = re.sub(r'[^<>+\-,.[\]]', '', args.in_file.read())

	main(brainf)
