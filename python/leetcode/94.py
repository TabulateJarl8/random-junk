"""Given the root of a binary tree, return the inorder traversal of its nodes' values."""

from typing import List, Optional


class TreeNode:
	def __init__(self, val=0, left=None, right=None):
		self.val = val
		self.left = left
		self.right = right


class Solution:
	def inorderTraversal(self, root: Optional[TreeNode]) -> List[int]:
		nodes = []
		if root:
			nodes.extend(self.inorderTraversal(root.left))
			nodes.append(root.val)
			nodes.extend(self.inorderTraversal(root.right))

		return nodes
