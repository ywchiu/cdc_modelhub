import glob
import sys
import pandas as pd

failed = False

for file in glob.glob('data/*.csv'):
    try:
        df = pd.read_csv(file)
        a = [c for c in df.columns if 'a' in c]
        if not a :
            break 
        print(f'OK - {len(df)} rows, {len(df.columns)} cols')
    except Exception as e:
        print(f'Failed - {e}')
        failed = True

sys.exit(1 if failed else 0)
