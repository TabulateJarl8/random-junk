class Solution:
    def isMatch(self, s: str, p: str) -> bool:
        char_is_match = lambda c, p: c == p or p == '?'
        
        s_index = 0

        pattern_iter = enumerate(p)

        for index, char in pattern_iter:

            if s_index == len(s):
                # check that we've iterated through both the string and the pattern successfully
                return index == len(p) or all(c == '*' for c in p[index:])

            if char == '?':
                # check that the index exists in s
                if s_index >= len(s):
                    return False
            elif char == '*':
                # any character

                # collapse repeating *s
                if index < len(p) - 1 and p[index + 1] == '*':
                    continue
                
                if index == len(p) - 1:
                    # matches the remainder of the string
                    return True
                else:
                    next_matching_char = p[index + 1]

                    s_index = len(s) - 1
                    # iterate in reverse (greedily)
                    while not char_is_match(s[s_index], next_matching_char):
                        s_index -= 1
                        if s_index == -1:
                            return False

                    if next_matching_char != '?':
                        # skip incrementing s_index so that the next loop cycle is a match
                        
                        continue
                    else:
                        next(pattern_iter)

            elif s[s_index] != char:
                # anything else
                return False

            s_index += 1

        return s_index == len(s)


print(Solution().isMatch('ab', '*?*?*'))