import re

e = re.compile(r'ab')

mo = e.search('abac')

print(mo)