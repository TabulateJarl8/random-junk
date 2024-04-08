class Solution:
    def checkValidString(self, s: str) -> bool:
        possible_closing_parenthesis = 0
        possible_opening_parenthesis = 0

        for char in s:
            if char == '(':
                possible_closing_parenthesis += 1
                possible_opening_parenthesis += 1
            elif char == ')':
                possible_closing_parenthesis -= 1
                possible_opening_parenthesis -= 1
            elif char == '*':
                possible_closing_parenthesis -= 1
                possible_opening_parenthesis += 1

            if possible_opening_parenthesis < 0:
                return False
            if possible_closing_parenthesis < 0:
                possible_closing_parenthesis = 0

        return possible_closing_parenthesis == 0
print(Solution().checkValidString("(((((*(()((((*((**(((()()*)()()()*((((**)())*)*)))))))(())(()))())((*()()(((()((()*(())*(()**)()(())"))
