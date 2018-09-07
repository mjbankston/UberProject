import time

s1 = 'This is a string'
s2 = "This is another string"
s3 = 'This string has a newline character at the end\n'
# User r in front of a string literal to prevent escape character from doing anything
s4 = r'This string does not have a new line character at the end\n'

s5 = ''' This is a
multiline
string!'''

s6 = 'So \
is \
this!'

# Print statement with a string ends with a new line, and therefore flushes automatically.
print('This will automatically flush.')

# Preventing the new line will prevent the flush.
print('Waiting for new line...', end='')
print('there we go.')

# If something hijacks the thread after preventing a flush, then flush needs to be true.
print('Waiting for a new line after sleeping...', end='', flush=True)
time.sleep(1)
print('there we go.')
