# the best blockchain that definitely wasn't just made in a few minutes because I was bored. It definitely doesn't have any security vulnerabilities whatsoever, don't worry.
import hashlib

class Block:
	def __init__(self, send_from, send_to, amount, last_block):
		self.send_from = send_from
		self.send_to = send_to
		self.amount = amount

		if last_block is None:
			self.last_hash = '0'
		else:
			self.last_hash = last_block.hash

		self.hash = None
		self.calc_hash()

	def calc_hash(self):
		hash = hashlib.sha256(repr(self).encode("utf-8"))
		self.hash = hash.hexdigest()

	def __repr__(self):
		return f'Block(send_to={repr(self.send_to)}, send_from={repr(self.send_from)}, amount={repr(self.amount)}, hash={repr(self.hash)}, last_hash={repr(self.last_hash)})'

class BlockChain:
	def __init__(self):
		self.chain = []

	def push_transaction(self, send_from, send_to, amount):
		if len(self.chain) > 1:
			# verify integrity
			if self.chain[-1].last_hash != self.chain[-2].hash:
				print('Error: hashes do not match. terminating transaction')
				return

		if len(self.chain) == 0:
			last_block = None
		else:
			last_block = self.chain[-1]

		self.chain.append(Block(send_from, send_to, amount, last_block))

	def __repr__(self):
		return '\n'.join([repr(block) for block in self.chain])

chain = BlockChain()
chain.push_transaction('Connor', 'Jame', 30)
chain.push_transaction('Jame', 'Connor', 1)
chain.push_transaction('Jame', "Jeq'uellen", 528)
print(chain)
