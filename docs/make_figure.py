"""Draw docs/validation_summary.png from the predictions written by notebook 03.

    python docs/make_figure.py
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.calibration import calibration_curve
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score, roc_curve

ROOT = Path(__file__).resolve().parents[1]
test = pd.read_csv(ROOT / "data" / "predictions.csv")
train = pd.read_csv(ROOT / "data" / "train_predictions.csv")
y = test["y_true"]


def logit(p):
    p = np.clip(np.asarray(p, dtype=float), 1e-6, 1 - 1e-6)
    return np.log(p / (1 - p)).reshape(-1, 1)


cal = LogisticRegression(C=1e6).fit(logit(train["y_prob_xgb"]), train["y_true"]).predict_proba(logit(test["y_prob_xgb"]))[:, 1]

fig, axes = plt.subplots(1, 3, figsize=(14, 4.2), dpi=150)
ax = axes[0]
for col, name, colour in (("y_prob_lr", "Logistic regression", "#1c7ed6"), ("y_prob_xgb", "XGBoost", "#e8590c")):
    fpr, tpr, _ = roc_curve(y, test[col])
    ax.plot(fpr, tpr, color=colour, lw=2, label=f"{name} (AUC {roc_auc_score(y, test[col]):.3f})")
ax.plot([0, 1], [0, 1], color="#adb5bd", ls="--", lw=1, label="No skill (AUC 0.500)")
ax.set(title="Discrimination", xlabel="False positive rate", ylabel="True positive rate")
ax.legend(fontsize=9, frameon=False, loc="lower right")

ax = axes[1]
for p, name, colour in ((test["y_prob_xgb"], "XGBoost, raw scores", "#adb5bd"), (cal, "XGBoost, recalibrated", "#e8590c")):
    obs, pred = calibration_curve(y, p, n_bins=10, strategy="quantile")
    ax.plot(pred, obs, "o-", color=colour, lw=2, ms=4, label=name)
ax.plot([0, 1], [0, 1], color="#495057", ls="--", lw=1, label="Perfect calibration")
ax.set(title="Calibration", xlabel="Predicted default probability", ylabel="Observed default rate", xlim=(0, 1), ylim=(0, 1))
ax.legend(fontsize=9, frameon=False, loc="upper left")

ax = axes[2]
rank = pd.qcut(test["y_prob_xgb"].rank(method="first"), 10, labels=range(10, 0, -1))
rates = y.groupby(rank, observed=True).mean().sort_index()
ax.bar(rates.index.astype(int), rates * 100, color="#e8590c")
ax.axhline(y.mean() * 100, color="#495057", ls="--", lw=1)
ax.text(10.4, y.mean() * 100 + 1.2, f"average {100 * y.mean():.0f}%", ha="right", fontsize=9, color="#495057")
ax.set(title="Risk ranking (XGBoost)", xlabel="Score decile (1 = riskiest)", ylabel="Observed default rate, %", xticks=range(1, 11))

for a in axes:
    a.spines[["top", "right"]].set_visible(False)
    title = a.get_title()
    a.set_title("")
    a.set_title(title, loc="left", fontsize=12)
fig.tight_layout()
fig.savefig(ROOT / "docs" / "validation_summary.png", facecolor="white")
print("decile default rates:", [round(float(v), 3) for v in rates])
