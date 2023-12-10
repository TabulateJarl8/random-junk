"""
Given a 2D integer array matrix, return the transpose of matrix.

The transpose of a matrix is the matrix flipped over its main diagonal,
switching the matrix's row and column indices.
"""
from typing import List


class Solution:
	def transpose(self, matrix: List[List[int]]) -> List[List[int]]:
		# create new empty matrix with correct number of cols
		new_matrix = []
		for _ in matrix[0]:
			new_matrix.append([])

		for col_i in range(len(matrix[0])):
			for row in matrix:
				new_matrix[col_i].append(row[col_i])

		return new_matrix


assert Solution().transpose([[1, 2, 3], [4, 5, 6], [7, 8, 9]]) == [
	[1, 4, 7],
	[2, 5, 8],
	[3, 6, 9],
]
assert Solution().transpose([[1, 2, 3], [4, 5, 6]]) == [[1, 4], [2, 5], [3, 6]]
