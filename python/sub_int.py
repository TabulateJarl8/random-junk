class Number:
    def __init__(self, val):
        self.val = val

    def __str__(self):
        return str(self.val)

    def __repr__(self):
        return repr(self.val)

    def __add__(self, other):
        if isinstance(other, str):
            return Number(str(self.val) + other)

        if isinstance(other, self):
            return Number(self.val + other.val)

        if isinstance(other, int):
            return Number(self.val + other)

    def __sub__(self, other):
        if isinstance(other, str):
            if str(self.val).endswith(other):
                return Number(int(str(self.val)[:len(other) * -1]))
            return self

        if isinstance(other, (int, float)):
            return Number(self.val - other)


test = Number(91)
print(test + "1")
print(test - "1")
