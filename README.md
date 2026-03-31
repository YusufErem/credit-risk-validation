# Credit Risk Scoring & Model Validation

Kredi kartı müşterilerinin temerrüt (default) riskini tahmin eden bir skorlama modeli geliştirmek ve bu modeli **validasyon bakışıyla** değerlendirmek amacıyla hazırlanmış bir projedir.

## Proje Amacı

Bu proje, model geliştirmenin ötesinde **model risk yönetimi** perspektifinden bir değerlendirme sunmayı hedefler:

- Lojistik Regresyon (champion) ve XGBoost (challenger) modelleri ile kredi temerrüt tahmini
- Nicel validasyon: ROC-AUC, KS, Gini, Brier Score, kalibrasyon analizi
- Segment bazlı performans değerlendirmesi (cinsiyet, yaş, eğitim, limit bandı)
- Population Stability Index (PSI) ile drift analizi
- SHAP değerleri ile model yorumlanabilirlik analizi
- Champion vs Challenger istatistiksel karşılaştırma (Bootstrap AUC fark testi)

## Veri Seti

**UCI - Default of Credit Card Clients**
- 30,000 müşteri gözlemi
- 23 bağımsız değişken (kredi limiti, demografi, ödeme geçmişi, ekstre/ödeme tutarları)
- Hedef değişken: Gelecek ay temerrüt (0/1)
- Default oranı: ~%22

## Teknolojiler

- **Python**: pandas, numpy, scikit-learn, statsmodels, xgboost, shap, matplotlib, seaborn
- **SQL**: DuckDB ile segment bazlı analiz sorguları
- **Jupyter Notebook**: Analiz ve raporlama ortamı

## Proje Yapısı

```
credit-risk-validation/
├── data/
│   ├── credit_default.csv          # Ham veri
│   ├── credit_features.csv         # İşlenmiş veri (türetilmiş değişkenlerle)
│   ├── predictions.csv             # Model tahminleri
│   └── train_predictions.csv       # Train tahminleri (PSI için)
├── notebooks/
│   ├── 01_data_understanding.ipynb # EDA ve SQL sorguları
│   ├── 02_feature_engineering.ipynb# Veri temizleme ve değişken türetme
│   ├── 03_model_development.ipynb  # Model kurulumu ve eğitimi
│   └── 04_validation_report.ipynb  # Validasyon raporu
├── sql/
│   └── exploratory_queries.sql     # DuckDB SQL sorguları
├── models/                         # Kaydedilmiş modeller
├── reports/                        # Grafik çıktıları
└── README.md
```

## Notebook Akışı

| # | Notebook | İçerik |
|---|---------|--------|
| 01 | Data Understanding | Veri profili, dağılımlar, korelasyon, DuckDB SQL sorguları |
| 02 | Feature Engineering | Veri temizleme, 16 türetilmiş değişken oluşturma |
| 03 | Model Development | Logistic Regression + XGBoost, cross-validation |
| 04 | Validation Report | ROC/KS/Gini, kalibrasyon, decile, segment, PSI, SHAP |

## Temel Bulgular

### Model Performansı
- Her iki model de baseline'ın (AUC=0.50) belirgin üzerinde ayrıştırma gücü sergilemiştir
- Lojistik Regresyon yorumlanabilirlik ve kalibrasyon açısından avantajlıdır

### En Güçlü Risk Sinyalleri
1. **Ödeme gecikme geçmişi** (PAY_0, MAX_DELINQUENCY) — en belirleyici değişkenler
2. **Limit kullanım oranı** (UTIL_RATIO) — yüksek kullanım default ile pozitif ilişkili
3. **Ödeme/ekstre oranı** — düşük ödeme oranı risk göstergesi

### Validasyon Bulguları
- Kalibrasyon analizi modelin olasılık tahminlerinin güvenilirliğini değerlendirmektedir
- Segment performansı farklı müşteri gruplarında model tutarlılığını göstermektedir
- PSI analizi popülasyon kararlılığını izlemektedir

## Çalıştırma

```bash
# Gerekli paketler
pip install pandas numpy scikit-learn matplotlib seaborn scipy statsmodels duckdb xgboost shap jupyter

# Notebook'ları sırayla çalıştır
jupyter notebook notebooks/01_data_understanding.ipynb
```

## Sınırlamalar

- Veri tek bir ülke/bağlam verisine dayanmaktadır (Tayvan, 2005)
- Zaman boyutu sınırlıdır (6 aylık gözlem penceresi)
- Gerçek üretim ortamı gözlenmediği için sonuçlar akademik çerçevededir
- Model karar desteği üretir; tek başına kredi tahsis kararı vermez
