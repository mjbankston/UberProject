from tqdm import tqdm
from tqdm import trange
import time

# Wrap any iterable with tqdm
for x in tqdm(range(100)):
    time.sleep(0.001)

for x in tqdm(['A', 'B', 'C', 'D']):
    time.sleep(0.1)

# Manual control
with tqdm(total=100) as pbar:
    for i in range(10):
        pbar.update(10)

# trange is an optimized version of tqdm(range(n))
for x in trange(100):
    time.sleep(0.001)
