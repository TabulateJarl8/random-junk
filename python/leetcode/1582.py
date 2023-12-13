"""
Given an m x n binary matrix mat, return the number of special positions in mat.

A position (i, j) is called special if mat[i][j] == 1 and all other elements in
row i and column j are 0 (rows and columns are 0-indexed).
"""

from typing import List


class Solution:
	def numSpecial(self, mat: List[List[int]]) -> int:
		cols = [[mat[j][i] for j in range(len(mat))] for i in range(len(mat[0]))]

		special = 0
		for index, row in enumerate(mat):
			if row.count(1) == 1 and cols[row.index(1)].count(1) == 1:
				special += 1

		return special


print(Solution().numSpecial([[1, 0, 0], [0, 1, 0], [0, 0, 1]]))
