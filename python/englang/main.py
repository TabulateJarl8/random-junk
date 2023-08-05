import argparse
import lexer
import transpiler
import os

def main():
	argparser = argparse.ArgumentParser(prog='englang', description='The English programming language')
	argparser.add_argument('filename')
	args = argparser.parse_args()

	with open(args.filename) as f:
		inst = lexer.lex(f.read())
		code = transpiler.transpile(inst)

		with open('test.c', 'w') as f:
			f.write('\n'.join(code))
	os.system('gcc test.c -o test')
	os.system('./test')

if __name__ == '__main__':
	main()