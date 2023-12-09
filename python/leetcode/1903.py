"""
You are given a string num, representing a large integer. Return the
largest-valued odd integer (as a string) that is a non-empty substring of num,
or an empty string "" if no odd integer exists.
"""
import sys

sys.set_int_max_str_digits(100000)


class Solution:
	def largestOddNumber(self, num: str) -> str:
		for i in range(len(num) - 1, -1, -1):
			if int(num[i]) % 2:
				return num[: i + 1]

		return ""
