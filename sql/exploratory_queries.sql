-- ============================================================
-- Kredi Riski Skorlama ve Model Validasyonu Projesi
-- Keşifsel SQL Sorguları (DuckDB uyumlu)
-- ============================================================

-- Bu dosya DuckDB ile çalıştırılmak üzere hazırlanmıştır.
-- Python'da: duckdb.sql("SELECT ...").show()

-- ============================================================
-- 1. GENEL VERİ PROFİLİ
-- ============================================================

-- 1.1 Temerrüt dağılımı
SELECT
    "default payment next month" AS default_flag,
    COUNT(*) AS n,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM credit_default
GROUP BY 1
ORDER BY 1;

-- 1.2 Temel istatistikler
SELECT
    COUNT(*) AS toplam_musteri,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit,
    ROUND(MEDIAN(LIMIT_BAL), 0) AS medyan_limit,
    ROUND(AVG(AGE), 1) AS ort_yas,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct
FROM credit_default;


-- ============================================================
-- 2. DEMOGRAFİK SEGMENT ANALİZLERİ
-- ============================================================

-- 2.1 Cinsiyete göre
SELECT
    CASE WHEN SEX = 1 THEN 'Erkek' ELSE 'Kadın' END AS cinsiyet,
    COUNT(*) AS n,
    SUM("default payment next month") AS default_sayisi,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit,
    ROUND(AVG(AGE), 1) AS ort_yas
FROM credit_default
GROUP BY SEX
ORDER BY default_orani_pct DESC;

-- 2.2 Eğitim seviyesine göre
SELECT
    CASE
        WHEN EDUCATION = 1 THEN '1-Lisansüstü'
        WHEN EDUCATION = 2 THEN '2-Üniversite'
        WHEN EDUCATION = 3 THEN '3-Lise'
        ELSE '4-Diğer'
    END AS egitim,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit
FROM credit_default
GROUP BY EDUCATION
ORDER BY EDUCATION;

-- 2.3 Medeni duruma göre
SELECT
    CASE
        WHEN MARRIAGE = 1 THEN 'Evli'
        WHEN MARRIAGE = 2 THEN 'Bekar'
        ELSE 'Diğer'
    END AS medeni_durum,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct
FROM credit_default
GROUP BY MARRIAGE
ORDER BY MARRIAGE;

-- 2.4 Yaş grubuna göre
SELECT
    CASE
        WHEN AGE < 25 THEN '20-24'
        WHEN AGE < 30 THEN '25-29'
        WHEN AGE < 35 THEN '30-34'
        WHEN AGE < 40 THEN '35-39'
        WHEN AGE < 50 THEN '40-49'
        ELSE '50+'
    END AS yas_grubu,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit
FROM credit_default
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 3. KREDİ LİMİTİ ANALİZLERİ
-- ============================================================

-- 3.1 Limit bandına göre default oranı
SELECT
    CASE
        WHEN LIMIT_BAL < 50000 THEN 'A: < 50K'
        WHEN LIMIT_BAL < 100000 THEN 'B: 50K-100K'
        WHEN LIMIT_BAL < 200000 THEN 'C: 100K-200K'
        WHEN LIMIT_BAL < 500000 THEN 'D: 200K-500K'
        ELSE 'E: 500K+'
    END AS limit_bandi,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(AGE), 1) AS ort_yas,
    ROUND(MIN(LIMIT_BAL), 0) AS min_limit,
    ROUND(MAX(LIMIT_BAL), 0) AS max_limit
FROM credit_default
GROUP BY 1
ORDER BY 1;

-- 3.2 Limit ve cinsiyet çapraz tablosu
SELECT
    CASE WHEN SEX = 1 THEN 'Erkek' ELSE 'Kadın' END AS cinsiyet,
    CASE
        WHEN LIMIT_BAL < 100000 THEN 'Düşük Limit'
        WHEN LIMIT_BAL < 300000 THEN 'Orta Limit'
        ELSE 'Yüksek Limit'
    END AS limit_bandi,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct
FROM credit_default
GROUP BY 1, 2
ORDER BY 1, 2;


-- ============================================================
-- 4. ÖDEME GECİKME ANALİZLERİ
-- ============================================================

-- 4.1 Son ay gecikme durumu ve default
SELECT
    PAY_0 AS son_ay_gecikme,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS populasyon_pct
FROM credit_default
GROUP BY PAY_0
ORDER BY PAY_0;

-- 4.2 Çapraz: Limit bandı x Gecikme → Default
SELECT
    CASE
        WHEN LIMIT_BAL < 100000 THEN 'Düşük Limit'
        WHEN LIMIT_BAL < 300000 THEN 'Orta Limit'
        ELSE 'Yüksek Limit'
    END AS limit_bandi,
    CASE
        WHEN PAY_0 <= 0 THEN 'Gecikme Yok'
        WHEN PAY_0 = 1 THEN '1 Ay Gecikme'
        ELSE '2+ Ay Gecikme'
    END AS gecikme_durumu,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct
FROM credit_default
GROUP BY 1, 2
ORDER BY 1, 2;

-- 4.3 Ardışık gecikme profili
SELECT
    CASE
        WHEN PAY_0 > 0 AND PAY_2 > 0 AND PAY_3 > 0 THEN 'Kronik Gecikmeli (3+ ay ardışık)'
        WHEN PAY_0 > 0 AND PAY_2 > 0 THEN 'Tekrarlayan Gecikmeli (2 ay ardışık)'
        WHEN PAY_0 > 0 THEN 'Tek Seferlik Gecikmeli'
        ELSE 'Gecikme Yok'
    END AS gecikme_profili,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit
FROM credit_default
GROUP BY 1
ORDER BY default_orani_pct DESC;


-- ============================================================
-- 5. MALİ ANALİZLER
-- ============================================================

-- 5.1 Ekstre/Ödeme oranı ve default
SELECT
    CASE
        WHEN BILL_AMT1 <= 0 THEN 'Sıfır/Negatif Ekstre'
        WHEN PAY_AMT1 * 1.0 / BILL_AMT1 >= 1.0 THEN 'Tam Ödeme (>=100%)'
        WHEN PAY_AMT1 * 1.0 / BILL_AMT1 >= 0.5 THEN 'Yüksek Ödeme (50-100%)'
        WHEN PAY_AMT1 * 1.0 / BILL_AMT1 >= 0.1 THEN 'Kısmi Ödeme (10-50%)'
        WHEN PAY_AMT1 > 0 THEN 'Asgari Ödeme (<10%)'
        ELSE 'Ödeme Yok'
    END AS odeme_profili,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct
FROM credit_default
GROUP BY 1
ORDER BY default_orani_pct DESC;

-- 5.2 Limit kullanım oranı ve default
SELECT
    CASE
        WHEN BILL_AMT1 <= 0 THEN 'Kullanım Yok'
        WHEN BILL_AMT1 * 1.0 / LIMIT_BAL < 0.3 THEN 'Düşük Kullanım (<30%)'
        WHEN BILL_AMT1 * 1.0 / LIMIT_BAL < 0.7 THEN 'Orta Kullanım (30-70%)'
        WHEN BILL_AMT1 * 1.0 / LIMIT_BAL < 1.0 THEN 'Yüksek Kullanım (70-100%)'
        ELSE 'Aşırı Kullanım (>=100%)'
    END AS util_bandi,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit
FROM credit_default
GROUP BY 1
ORDER BY default_orani_pct DESC;


-- ============================================================
-- 6. RİSK SEGMENTLEMESİ
-- ============================================================

-- 6.1 Kombine risk profili
SELECT
    CASE
        WHEN PAY_0 > 1 AND BILL_AMT1 * 1.0 / NULLIF(LIMIT_BAL, 0) > 0.7 THEN 'Yüksek Risk'
        WHEN PAY_0 > 0 OR BILL_AMT1 * 1.0 / NULLIF(LIMIT_BAL, 0) > 0.7 THEN 'Orta Risk'
        ELSE 'Düşük Risk'
    END AS risk_segmenti,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_orani_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS ort_limit,
    ROUND(AVG(AGE), 1) AS ort_yas
FROM credit_default
GROUP BY 1
ORDER BY default_orani_pct DESC;
