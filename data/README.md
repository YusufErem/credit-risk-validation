# Data

The data files are not stored in this repository; `download_data.py` fetches them from the source.

## Data Source
**UCI Machine Learning Repository - Default of Credit Card Clients**
- URL: https://archive.ics.uci.edu/dataset/350/default+of+credit+card+clients
- 30,000 customers, 25 variables
- License: CC BY 4.0. Citation: Yeh, I. (2009). *Default of Credit Card Clients* [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C55S3H

## Running the Notebooks
```bash
python data/download_data.py     # writes data/credit_default.csv
# then run the notebooks in order (01 → 02 → 03 → 04)
```
