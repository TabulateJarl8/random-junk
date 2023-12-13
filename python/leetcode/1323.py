"""
You are given a positive integer num consisting only of digits 6 and 9.

Return the maximum number you can get by changing at most one digit
(6 becomes 9, and 9 becomes 6).
"""


class Solution:
	def maximum69Number(self, num: int) -> int:
		orig_num = num
		# get tens places

		tens_places = 0
		while num > 0:
			num //= 10
			tens_places += 1

		extractor = 10 ** (tens_places - 1)

		while extractor != 0 and (orig_num // extractor) % 10 != 6:
			print(extractor, (orig_num // extractor) % 10)
			extractor //= 10

		return orig_num + extractor * 3


print(Solution().maximum69Number(96699))
