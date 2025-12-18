import glob
import sys
import pandas as pd

failed = False

for file in glob.glob('data/*.csv'):
    try:
        df = pd.read_csv(file)
        print(f'OK - {len(df)} rows, {len(df.columns)} cols')
    except Exception as e:
        print(f'Failed - {e}')
        failed = True

sys.exit(1 if failed else 0)
