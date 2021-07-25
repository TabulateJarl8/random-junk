from pynput.keyboard import Key, Listener # pip3 install pynput
import time

class KeyLogger:
	def __init__(self):
		self.last_key = ''

	def getKey(self, key):
		self.last_key = key

	def get_last_key(self):
		key = self.last_key
		self.last_key = ''
		return key

if __name__ == '__main__':
	test = KeyLogger()
	listener = Listener(on_press=test.getKey)
	listener.start()
	while True:
		print('test')
		print(test.get_last_key())
		time.sleep(1)