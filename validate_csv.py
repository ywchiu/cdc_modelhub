import glob
import sys
import pandas as pd

failed = False

for file in glob.glob('data/*.csv'):
    df = pd.read_csv(file)
    a = [c for c in df.columns if 'a' in c]
    if not a :
        assert 1 == 0 

