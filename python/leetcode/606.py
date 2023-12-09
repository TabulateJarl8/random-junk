"""
Given the root of a binary tree, construct a string consisting of parenthesis
and integers from a binary tree with the preorder traversal way, and return it.

Omit all the empty parenthesis pairs that do not affect the one-to-one mapping
relationship between the string and the original binary tree.
"""

from typing import Optional


class TreeNode:
	def __init__(self, val=0, left=None, right=None):
		self.val = val
		self.left = left
		self.right = right


class Solution:
	def tree2str(self, root: Optional[TreeNode]) -> str:
		if root:
			string = str(root.val)
			if root.left:
				string += f'({self.tree2str(root.left)})'

			if root.right:
				if not root.left:
					string += '()'
				string += f'({self.tree2str(root.right)})'

			return string
		else:
			return ''
