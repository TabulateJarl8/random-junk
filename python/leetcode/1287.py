"""
Given an integer array sorted in non-decreasing order, there is exactly one
integer in the array that occurs more than 25% of the time, return that integer.
"""

from typing import List


class Solution:
    def findSpecialInteger(self, arr: List[int]) -> int:
        counts = {
            num: arr.count(num)
            for num in set(arr)
        }
        return max(counts, key=lambda k: counts[k])
