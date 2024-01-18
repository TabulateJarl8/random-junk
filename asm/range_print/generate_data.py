import textwrap
data = ''

# "number {i}\n"
for num in [f'6e756d62657220{str(i).encode().hex():0<4}0a' for i in range(5, 61)]:
	data += ', '.join(['0x' + split for split in textwrap.wrap(num, 2)]) + ', '

data = data.rstrip(', ')

print(data)