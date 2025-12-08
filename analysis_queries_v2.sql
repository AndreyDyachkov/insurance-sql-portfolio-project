


-- ANALYSIS QUERIES
-- 1. Gross Premium Written (GPW) by selected Line of Business (LOB) ordered by Year
SELECT 
    dpt.policy_type_name AS "LOB",
    EXTRACT(YEAR FROM fp.start_date) AS "Year",
    SUM(fp.premium_amount) AS "GPW"
FROM FactPolicies fp
    JOIN DimProduct dp ON dp.product_id = fp.product_id
    JOIN DimPolicyType dpt ON dpt.policy_type_id = dp.policy_type_id  
-- Filter target LOBs
WHERE dpt.policy_type_name IN ('Health', 'Travel')
GROUP BY 
    dpt.policy_type_name,
    EXTRACT(YEAR FROM fp.start_date)
ORDER BY
    "LOB",
    "Year";

-- 2. Top 3 Customers by Payout Amount
SELECT 
    dc.full_name,
    COUNT(fc.claim_id) AS "Number of Claims",
    SUM(fc.payout_amount) AS "Total Payout"
FROM FactClaims fc
    JOIN FactPolicies fp ON fp.policy_id = fc.policy_id
    JOIN DimCustomer dc ON dc.customer_id = fp.customer_id
GROUP BY dc.full_name
ORDER BY "Total Payout" DESC
LIMIT 3;

-- 3. Running Total of Monthly GPW by Year (Common Table Expression (CTE) + Window Function)
-- Aggregate premium by year and month
WITH monthly_premium AS (
    SELECT 
        EXTRACT(YEAR FROM start_date) AS year,
        EXTRACT(MONTH FROM start_date) AS month,
        SUM(premium_amount) AS monthly_premium
    FROM FactPolicies
    GROUP BY
        EXTRACT(YEAR FROM start_date),
        EXTRACT(MONTH FROM start_date) 
)
-- Calculate Running Total
SELECT
    year,
    month,
    monthly_premium,
    -- Running total resets every year due to PARTITION BY year
    SUM(monthly_premium) OVER(
        PARTITION BY year 
        ORDER BY month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "Running Total GPW"
FROM monthly_premium
ORDER BY
    year,
    month;

-- 4. Ranking Customers by Lifetime Net Value (LTV) (Window Function)
SELECT 
    dc.customer_id,
    dc.full_name,
    -- LTV = GPW*(1 - Acquisition Rate) - Loss, COALESCE replaces NULL (no claims) with 0
    SUM(fp.premium_amount)*(1 - 0.2) - COALESCE(SUM(fc.payout_amount),0) AS "LTV",
    -- Window function assigns rank based on calculated LTV
    RANK() OVER (
        ORDER BY SUM(fp.premium_amount)*(1 - 0.2) - COALESCE(SUM(fc.payout_amount),0) DESC
    ) AS "LTV Rank"
FROM DimCustomer dc
    JOIN FactPolicies fp ON fp.customer_id = dc.customer_id
    LEFT JOIN FactClaims fc ON fc.policy_id = fp.policy_id
GROUP BY dc.customer_id, dc.full_name;


-- 5 Customers with More Than 2 Claims per Policy (Nested Query)
SELECT 
    dpt.policy_type_name,
    dc.customer_id, 
    dc.full_name, 
    dr.region_name
FROM DimCustomer dc
    JOIN FactPolicies fp ON fp.customer_id = dc.customer_id
    JOIN DimRegion dr ON dr.region_id = dc.region_id
    JOIN DimProduct dp ON dp.product_id = fp.product_id
    JOIN DimPolicyType dpt ON dpt.policy_type_id = dp.policy_type_id  
WHERE fp.policy_id IN (
    SELECT policy_id
    FROM FactClaims
    GROUP BY policy_id
    HAVING COUNT(claim_id) > 2
)
ORDER BY dr.region_name;

-- 6 Customers with More Than 2 Claims in the Past Year
SELECT 
    dc.customer_id,
    dc.full_name, 
    COUNT(fc.claim_id) AS "Number of Claims"
FROM DimCustomer dc, FactPolicies fp, FactClaims fc
WHERE dc.customer_id = fp.customer_id
    AND fp.policy_id = fc.policy_id
    -- Only last 12 months
    AND fc.reported_date >= NOW() - INTERVAL '1 year'
GROUP BY 
    dc.customer_id, 
    dc.full_name
HAVING COUNT(claim_id) > 2;

-- 7 Claim Frequency for Expired Policies by Line of Business (LOB) and Year
SELECT 
    dpt.policy_type_name AS "LOB",
    dp.product_name AS "Product",
    EXTRACT(YEAR FROM fp.end_date) AS year,
    COUNT(DISTINCT fp.policy_id) AS "Number of policies",
    COUNT(DISTINCT fc.claim_id) AS "Number of claims",
    -- Frequency  = Claims / Policies
    ROUND(
        COUNT(DISTINCT fc.claim_id)::numeric / COUNT(DISTINCT fp.policy_id), 4
    ) AS "Frequency"
FROM FactPolicies fp
    -- LEFT JOIN to count policies with no claims
    LEFT JOIN FactClaims fc ON fp.policy_id = fc.policy_id
    JOIN DimProduct dp ON dp.product_id = fp.product_id
    JOIN DimPolicyType dpt ON dpt.policy_type_id = dp.policy_type_id 
GROUP BY 
    dpt.policy_type_name,
    dp.product_name, 
    EXTRACT(YEAR FROM fp.end_date)
ORDER BY 
    "LOB",
    year;

-- 8. Exposure-Based Frequency for 1Q2025
-- (Frequency = Claims / Exposure, Exposure =  Active Days in Period / Total Policy Days)
-- (Common Table Expressions (CTE))
WITH period_params AS (
    SELECT 
        DATE '2025-01-01' AS period_start_date,
        DATE '2025-03-31' AS period_end_date
 ),
calc_overlap AS (
    SELECT
        fp.policy_id,
        fp.start_date,
        fp.end_date,
         -- Total number of days in the policy period (+1 because both start and end dates are inclusive)
        (fp.end_date - fp.start_date) + 1 AS policy_period_days,  
        pp.period_start_date,
        pp.period_end_date,
        -- Start of overlap window (later of the two dates)
        GREATEST(fp.start_date,pp.period_start_date) AS overlap_start,
        -- End of overlap window (earlier of the two dates)
        LEAST(fp.end_date, pp.period_end_date) AS overlap_end
    FROM FactPolicies fp
    -- Attach period to each policy
    CROSS JOIN period_params pp
    -- Ensure there is at least 1 day overlap
    WHERE fp.start_date <= pp.period_end_date
        AND fp.end_date >= pp.period_start_date
),
calc_exposure AS(
    SELECT
        fp.policy_id,
        fp.premium_amount,
        co.start_date,
        co.end_date,
        co.policy_period_days,
        co.period_start_date,
        co.period_end_date,
        co.overlap_start,
        co.overlap_end,
        -- Actual days the policy was active within reporting period
        (co.overlap_end - co.overlap_start) +1 AS overlap_days,
        -- Exposure = actual days in period / total_policy_days
        ((co.overlap_end - co.overlap_start) +1) :: numeric / co.policy_period_days AS exposure
    FROM calc_overlap co
    JOIN FactPolicies fp USING (policy_id) -- JOIN tables by the same column
)
SELECT 
    dpt.policy_type_name AS "LOB",
    dp.product_name AS "Product",
    COUNT(DISTINCT fc.claim_id) AS "Number of Claims",
    -- Exposure aggregated across all policies
    ROUND(SUM(exposure),2) AS "Total Exposure",
    -- Frequency = claims / exposure
    ROUND(COUNT(DISTINCT fc.claim_id) / SUM(exposure),4) AS "Frequency"
FROM calc_exposure ce
    LEFT JOIN FactClaims fc ON fc.policy_id = ce.policy_id
        AND fc.occurred_date >=  ce.period_start_date
        AND fc.occurred_date <=  ce.period_end_date
    JOIN FactPolicies fp ON ce.policy_id = fp.policy_id
    JOIN DimProduct dp ON dp.product_id = fp.product_id
    JOIN DimPolicyType dpt ON dpt.policy_type_id = dp.policy_type_id
GROUP BY 
    dpt.policy_type_name,
    dp.product_name;

-- 9. Claim Severity (Total Loss / Number of Claims) by Line of Business(LOB) and Year
SELECT 
    dpt.policy_type_name AS "LOB",
    dp.product_name AS "Product",
    EXTRACT(YEAR FROM fp.end_date) AS year,
    -- Total paid losses
    SUM(fc.payout_amount) AS "Total Loss",
    COUNT(DISTINCT fc.claim_id) AS "Number of claims",
    -- Severity = Total Loss / Number of Claims
    ROUND(SUM(fc.payout_amount)::numeric / COUNT(DISTINCT fc.claim_id), 2) AS "Severity"
FROM FactClaims fc
    JOIN FactPolicies fp ON fp.policy_id = fc.policy_id
    JOIN DimProduct dp ON dp.product_id = fp.product_id
    JOIN DimPolicyType dpt ON dpt.policy_type_id = dp.policy_type_id
GROUP BY 
    dpt.policy_type_name,
    dp.product_name,
    EXTRACT(YEAR FROM fp.end_date)
ORDER BY 
    "LOB", 
    year;

-- 10 Gross Premium Earned (GPE) per Line of Business, pro rata calculation (Common Table Expressions (CTE))
WITH period_params AS (
    SELECT 
        DATE '2025-01-01' AS period_start_date,
        DATE '2025-03-31' AS period_end_date
 ),
calc_overlap AS (
    SELECT
        fp.policy_id,
        fp.start_date,
        fp.end_date,
        -- Total number of days in the policy period (+1 because both start and end dates are inclusive)
        (fp.end_date - fp.start_date) + 1 AS policy_period_days,
        pp.period_start_date,
        pp.period_end_date,
        -- Start of overlap window (later of the two dates)
        GREATEST(fp.start_date,pp.period_start_date) AS overlap_start,
        -- End of overlap window (earlier of the two dates)
        LEAST(fp.end_date, pp.period_end_date) AS overlap_end
    FROM FactPolicies fp
        -- Attach period to each policy
        CROSS JOIN period_params pp
    -- Ensure there is at least 1 day overlap
    WHERE fp.start_date <= pp.period_end_date
        AND fp.end_date >= pp.period_start_date
),
premium_earned AS(
    SELECT
        fp.policy_id,
        fp.premium_amount,
        co.start_date,
        co.end_date,
        co.policy_period_days,
        co.period_start_date,
        co.period_end_date,
        co.overlap_start,
        co.overlap_end,
        -- Actual days the policy was active within reporting period
        (co.overlap_end - co.overlap_start) +1 AS overlap_days,
        -- GPE in 1Q2025 = GPW * (actual days in 1Q2025) / (total policy days)) 
        fp.premium_amount * ((co.overlap_end - co.overlap_start) +1) :: numeric / co.policy_period_days AS gross_premium_earned
    FROM calc_overlap co
        JOIN FactPolicies fp USING (policy_id) -- JOIN tables by the same column
)
SELECT 
    dpt.policy_type_name AS "LOB",
    dp.product_name AS "Product",
    -- Aggregated GPE
    ROUND(SUM(pe.gross_premium_earned),2) AS "GPE"
FROM premium_earned pe
    JOIN FactPolicies fp ON pe.policy_id = fp.policy_id
    JOIN DimProduct dp ON dp.product_id = fp.product_id
    JOIN DimPolicyType dpt ON dpt.policy_type_id = dp.policy_type_id
GROUP BY 
    dpt.policy_type_name,
    dp.product_name
ORDER BY "GPE" DESC;
