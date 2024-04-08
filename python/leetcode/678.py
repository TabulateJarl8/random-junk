class Solution:
    def checkValidString(self, s: str) -> bool:
        count = 0
        for char in s:
            if char == '(':
                count += 1
            elif char == ')':
                count -= 1

        star_count = s.count('*')
        return any(item == 0 for item in [count, count - star_count, count + star_count])
