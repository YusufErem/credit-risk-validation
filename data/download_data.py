"""Download the UCI 'Default of Credit Card Clients' data set and write data/credit_default.csv.

    python data/download_data.py        # needs pandas and xlrd
"""
import io
import urllib.request
import zipfile
from pathlib import Path

import pandas as pd

URL = "https://archive.ics.uci.edu/static/public/350/default+of+credit+card+clients.zip"
OUT = Path(__file__).resolve().parent / "credit_default.csv"

if __name__ == "__main__":
    with urllib.request.urlopen(URL) as r, zipfile.ZipFile(io.BytesIO(r.read())) as z:
        name = next(n for n in z.namelist() if n.endswith(".xls"))
        df = pd.read_excel(io.BytesIO(z.read(name)), header=1)
    df.to_csv(OUT, index=False)
    print(f"wrote {OUT}: {df.shape[0]:,} rows, {df.shape[1]} columns")
