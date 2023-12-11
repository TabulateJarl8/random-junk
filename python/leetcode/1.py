"""
Given an array of integers nums and an integer target, return indices of the
two numbers such that they add up to target.
"""
from typing import List


class Solution:
	def twoSum(self, nums: List[int], target: int) -> List[int]:
		for current_pointer in range(len(nums)):
			for combination_pointer in range(current_pointer + 1, len(nums)):
				if nums[current_pointer] + nums[combination_pointer] == target:
					return [current_pointer, combination_pointer]
