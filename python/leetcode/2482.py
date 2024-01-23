"""
You are given a 0-indexed m x n binary matrix grid.

A 0-indexed m x n difference matrix diff is created with the following procedure:

    Let the number of ones in the ith row be onesRowi.
    Let the number of ones in the jth column be onesColj.
    Let the number of zeros in the ith row be zerosRowi.
    Let the number of zeros in the jth column be zerosColj.
    diff[i][j] = onesRowi + onesColj - zerosRowi - zerosColj

Return the difference matrix diff.
"""

from typing import List


class Solution:
    def onesMinusZeros(self, grid: List[List[int]]) -> List[List[int]]:
        inv_grid = [[item for item in row] for row in grid]
        
        
        for i in range(len(grid)):
            diff.append([])

            ones_row = grid[i].count(1)
            zeros_row = grid[i].count(0)
            for j in range(len(inv_grid)):
                ones_col = inv_grid[i][j].count(0)
                zeros_col = inv_grid[i][j].count(0)