#!/usr/bin/env python3
"""
Example of recursive function to get the number of digits that match in the two integers

This was created in about 3 minutes because I was bored and saw someone asking how to on reddit

PEP-8 Compliant
"""

def get_num_matches(num1, num2, matches=0):
	"""
	Recursive function to get the number of matching characters
	between num1 and num2
	"""
	num1 = str(num1)
	num2 = str(num2)

	if len(num1) == 0 or len(num2) == 0:
		return matches

	# pad with zeros since those count
	if len(num1) > len(num2):
		num2 = num2.zfill(len(num1))
	else:
		num1 = num1.zfill(len(num2))

	if num1[-1] == num2[-1]:
		matches += 1

	return get_num_matches(num1[:-1], num2[:-1], matches)

print(get_num_matches(input('num1: '), input('sum2: ')))
