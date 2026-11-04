-- ============================================================
-- Credit Risk Scoring and Model Validation Project
-- Exploratory SQL Queries (DuckDB compatible)
-- ============================================================

-- This file is intended to be run with DuckDB.
-- In Python: duckdb.sql("SELECT ...").show()

-- ============================================================
-- 1. OVERALL DATA PROFILE
-- ============================================================

-- 1.1 Default distribution
SELECT
    "default payment next month" AS default_flag,
    COUNT(*) AS n,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM credit_default
GROUP BY 1
ORDER BY 1;

-- 1.2 Basic statistics
SELECT
    COUNT(*) AS total_customers,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit,
    ROUND(MEDIAN(LIMIT_BAL), 0) AS median_limit,
    ROUND(AVG(AGE), 1) AS avg_age,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct
FROM credit_default;


-- ============================================================
-- 2. DEMOGRAPHIC SEGMENT ANALYSES
-- ============================================================

-- 2.1 By gender
SELECT
    CASE WHEN SEX = 1 THEN 'Male' ELSE 'Female' END AS gender,
    COUNT(*) AS n,
    SUM("default payment next month") AS default_count,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit,
    ROUND(AVG(AGE), 1) AS avg_age
FROM credit_default
GROUP BY SEX
ORDER BY default_rate_pct DESC;

-- 2.2 By education level
SELECT
    CASE
        WHEN EDUCATION = 1 THEN '1-Graduate'
        WHEN EDUCATION = 2 THEN '2-University'
        WHEN EDUCATION = 3 THEN '3-High School'
        ELSE '4-Other'
    END AS education_level,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit
FROM credit_default
GROUP BY EDUCATION
ORDER BY EDUCATION;

-- 2.3 By marital status
SELECT
    CASE
        WHEN MARRIAGE = 1 THEN 'Married'
        WHEN MARRIAGE = 2 THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct
FROM credit_default
GROUP BY MARRIAGE
ORDER BY MARRIAGE;

-- 2.4 By age group
SELECT
    CASE
        WHEN AGE < 25 THEN '20-24'
        WHEN AGE < 30 THEN '25-29'
        WHEN AGE < 35 THEN '30-34'
        WHEN AGE < 40 THEN '35-39'
        WHEN AGE < 50 THEN '40-49'
        ELSE '50+'
    END AS age_group,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit
FROM credit_default
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- 3. CREDIT LIMIT ANALYSES
-- ============================================================

-- 3.1 Default rate by limit band
SELECT
    CASE
        WHEN LIMIT_BAL < 50000 THEN 'A: < 50K'
        WHEN LIMIT_BAL < 100000 THEN 'B: 50K-100K'
        WHEN LIMIT_BAL < 200000 THEN 'C: 100K-200K'
        WHEN LIMIT_BAL < 500000 THEN 'D: 200K-500K'
        ELSE 'E: 500K+'
    END AS limit_band,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(AGE), 1) AS avg_age,
    ROUND(MIN(LIMIT_BAL), 0) AS min_limit,
    ROUND(MAX(LIMIT_BAL), 0) AS max_limit
FROM credit_default
GROUP BY 1
ORDER BY 1;

-- 3.2 Limit and gender cross-tabulation
SELECT
    CASE WHEN SEX = 1 THEN 'Male' ELSE 'Female' END AS gender,
    CASE
        WHEN LIMIT_BAL < 100000 THEN 'Low Limit'
        WHEN LIMIT_BAL < 300000 THEN 'Medium Limit'
        ELSE 'High Limit'
    END AS limit_band,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct
FROM credit_default
GROUP BY 1, 2
ORDER BY 1, 2;


-- ============================================================
-- 4. PAYMENT DELINQUENCY ANALYSES
-- ============================================================

-- 4.1 Most recent month delinquency status and default
SELECT
    PAY_0 AS recent_month_delinquency,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS population_pct
FROM credit_default
GROUP BY PAY_0
ORDER BY PAY_0;

-- 4.2 Cross: Limit band x Delinquency → Default
SELECT
    CASE
        WHEN LIMIT_BAL < 100000 THEN 'Low Limit'
        WHEN LIMIT_BAL < 300000 THEN 'Medium Limit'
        ELSE 'High Limit'
    END AS limit_band,
    CASE
        WHEN PAY_0 <= 0 THEN 'No Delinquency'
        WHEN PAY_0 = 1 THEN '1 Month Delinquent'
        ELSE '2+ Months Delinquent'
    END AS delinquency_status,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct
FROM credit_default
GROUP BY 1, 2
ORDER BY 1, 2;

-- 4.3 Consecutive delinquency profile
SELECT
    CASE
        WHEN PAY_0 > 0 AND PAY_2 > 0 AND PAY_3 > 0 THEN 'Chronic Delinquent (3+ consecutive months)'
        WHEN PAY_0 > 0 AND PAY_2 > 0 THEN 'Repeat Delinquent (2 consecutive months)'
        WHEN PAY_0 > 0 THEN 'One-Time Delinquent'
        ELSE 'No Delinquency'
    END AS delinquency_profile,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit
FROM credit_default
GROUP BY 1
ORDER BY default_rate_pct DESC;


-- ============================================================
-- 5. FINANCIAL ANALYSES
-- ============================================================

-- 5.1 Statement/payment ratio and default
SELECT
    CASE
        WHEN BILL_AMT1 <= 0 THEN 'Zero/Negative Statement Balance'
        WHEN PAY_AMT1 * 1.0 / BILL_AMT1 >= 1.0 THEN 'Full Payment (>=100%)'
        WHEN PAY_AMT1 * 1.0 / BILL_AMT1 >= 0.5 THEN 'High Payment (50-100%)'
        WHEN PAY_AMT1 * 1.0 / BILL_AMT1 >= 0.1 THEN 'Partial Payment (10-50%)'
        WHEN PAY_AMT1 > 0 THEN 'Minimum Payment (<10%)'
        ELSE 'No Payment'
    END AS payment_profile,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct
FROM credit_default
GROUP BY 1
ORDER BY default_rate_pct DESC;

-- 5.2 Limit utilization ratio and default
SELECT
    CASE
        WHEN BILL_AMT1 <= 0 THEN 'No Utilization'
        WHEN BILL_AMT1 * 1.0 / LIMIT_BAL < 0.3 THEN 'Low Utilization (<30%)'
        WHEN BILL_AMT1 * 1.0 / LIMIT_BAL < 0.7 THEN 'Medium Utilization (30-70%)'
        WHEN BILL_AMT1 * 1.0 / LIMIT_BAL < 1.0 THEN 'High Utilization (70-100%)'
        ELSE 'Excessive Utilization (>=100%)'
    END AS utilization_band,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit
FROM credit_default
GROUP BY 1
ORDER BY default_rate_pct DESC;


-- ============================================================
-- 6. RISK SEGMENTATION
-- ============================================================

-- 6.1 Combined risk profile
SELECT
    CASE
        WHEN PAY_0 > 1 AND BILL_AMT1 * 1.0 / NULLIF(LIMIT_BAL, 0) > 0.7 THEN 'High Risk'
        WHEN PAY_0 > 0 OR BILL_AMT1 * 1.0 / NULLIF(LIMIT_BAL, 0) > 0.7 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_segment,
    COUNT(*) AS n,
    ROUND(AVG("default payment next month") * 100, 2) AS default_rate_pct,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit,
    ROUND(AVG(AGE), 1) AS avg_age
FROM credit_default
GROUP BY 1
ORDER BY default_rate_pct DESC;
