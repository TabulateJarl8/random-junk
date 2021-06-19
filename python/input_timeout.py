try:
	import msvcrt, time # Windows
except ModuleNotFoundError:
	import select # Unix

import sys

class TimedInput:
	def input(self, text, timeout_s, default=None):
		if 'select' in sys.modules:
			# Unix
			return self._unix_input(text, timeout_s, default)
		else:
			# Windows
			return self._windows_input(text, timeout_s, default)

	def _unix_input(self, text, timeout_s, default):
		sys.stdout.write(text)
		sys.stdout.flush()
		rlist, _, _ = select.select([sys.stdin], [], [], timeout_s)
		if rlist:
			return sys.stdin.readline()
		else:
			print()
			return default

	def _windows_input(self, text, timeout_s, default):
		start_time = time.time()
		sys.stdout.write(text)
		sys.stdout.flush()
		current = ''
		while True:
			if msvcrt.kbhit():
				c = msvcrt.getche()
				if ord(c) == 13: # Enter
					break
				elif ord(c) >= 32: # Character
					current += c.decode('utf-8')
			if (time.time() - start_time) > timeout_s:
				break

		print()
		if len(current) > 0:
			return current
		else:
			return default

timed_input = TimedInput()
result = timed_input.input('? ', 3)
print(result)
