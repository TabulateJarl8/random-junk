"""
Given the array of integers nums, you will choose two different indices i and j
of that array. Return the maximum value of (nums[i]-1)*(nums[j]-1). 
"""

from typing import List


class Solution:
	def maxProduct(self, nums: List[int]) -> int:
		# technically, we don't have to preserve the array
		first = max(nums)
		nums.remove(first)
		second = max(nums)
		return (first - 1) * (second - 1)


print(Solution().maxProduct([3, 4, 5, 2]))
