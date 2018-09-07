n = 2  # This produces an int
n = 2 / 4  # This produces a float
n = 2 / 5  # This produces a float
n = 2 // 5  # This produces an int (discards floating point section)
n = 2 % 5  # This produces an int (remainder after division)

# Power of symbol
n = 2 ** 5  # 2 to the power of 5 (produces an int)


# Complex numbers
com1 = 2 + 6j
com2 = 3 - 7j

com = com1 + com2
print(com)
com = com1 - com2
print(com)
com = com1 * com2
print(com)
com = com1 / com2
print(com)

try:
    com = com1 // com2
except TypeError:
    print("Can't take floor of complex number.")

try:
    com = com1 % com2
except TypeError:
    print("Can't mod complex numbers")

com = com1 ** com2
print(com)
