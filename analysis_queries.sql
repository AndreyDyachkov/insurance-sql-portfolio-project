


-- ANALYSIS QUERIES
-- 1. Gross Premium Written (GPW) by Line of Business (LOB) and Year
SELECT 
    ip.policy_type AS "Line of Business",
    EXTRACT(YEAR FROM ip.start_date) AS "Year",
    SUM(ip.premium_amount) AS "Gross Premium Written"
FROM insurance_policy ip
-- Filter target LOBs
WHERE ip.policy_type IN ('Home','Motor','Health')
GROUP BY 
    ip.policy_type,
    EXTRACT(YEAR FROM ip.start_date)
ORDER BY 
    ip.policy_type,
    "Year";

-- 2. Top 3 Customers by Payout Amount
SELECT 
    c.full_name,
    COUNT(cl.claim_id) AS "Number of Claims",
    SUM(cl.payout_amount) AS "Total Payout"
FROM claim cl
    JOIN insurance_policy ip ON ip.policy_id = cl.policy_id
    JOIN customer c ON c.customer_id = ip.customer_id
GROUP BY c.full_name
ORDER BY "Total Payout" DESC
LIMIT 3;

-- 3. Running Total of Monthly GPW by Year (Common Table Expression (CTE) + Window Function)
WITH monthly_premium AS (
    SELECT 
        EXTRACT(YEAR FROM start_date) AS year,
        EXTRACT(MONTH FROM start_date) AS month,
        SUM(premium_amount) AS monthly_premium
    FROM insurance_policy
    GROUP BY
        EXTRACT(YEAR FROM start_date),
        EXTRACT(MONTH FROM start_date) 
)
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

-- 4. Ranking Customers by Lifetime Net Value (Window Function)
SELECT 
    c.customer_id,
    c.full_name,
    -- LTV = GPW*(1 - Acquisition Rate) - Loss, COALESCE replaces NULL (no claims) with 0
    SUM(ip.premium_amount)*(1 - 0.2) - COALESCE(SUM(cl.payout_amount),0) AS "Net Value",
    -- Window function assigns rank based on calculated LTV
    RANK() OVER (
        ORDER BY SUM(ip.premium_amount)*0.8 - COALESCE(SUM(cl.payout_amount),0) DESC
    ) AS "LTV Rank"
FROM customer c
    JOIN insurance_policy ip ON ip.customer_id = c.customer_id
    LEFT JOIN claim cl ON cl.policy_id = ip.policy_id
GROUP BY c.customer_id, c.full_name;


-- 5 Customers with More Than 2 Claims per Policy (Nested Query)
SELECT 
    ip.policy_type,
    c.customer_id, 
    c.full_name, 
    c.region
FROM customer c
    JOIN insurance_policy ip ON ip.customer_id = c.customer_id
WHERE ip.policy_id IN (
    SELECT policy_id
    FROM claim
    GROUP BY policy_id
    HAVING COUNT(claim_id) > 2
)
ORDER BY ip.policy_type;

-- 6 Customers with More Than 2 Claims in the Past Year
SELECT 
    c.customer_id,
    c.full_name, 
    COUNT(cl.claim_id) AS "Number of Claims"
FROM customer c, insurance_policy ip, claim cl
WHERE c.customer_id = ip.customer_id
    AND ip.policy_id = cl.policy_id
    -- Only last 12 months
    AND cl.reporting_date >= NOW() - INTERVAL '1 year'
GROUP BY 
    c.customer_id, 
    c.full_name
HAVING COUNT(claim_id) > 2;

-- 7 Claim Frequency for Expired Policies by Line of Business and Year
SELECT 
    ip.policy_type AS "Line of Business",
    EXTRACT(YEAR FROM ip.end_date) AS year,
    COUNT(DISTINCT ip.policy_id) AS "Number of policies",
    COUNT(DISTINCT cl.claim_id) AS "Number of claims",
    -- (Frequency  = Claims / Policies)
    ROUND(
        COUNT(DISTINCT cl.claim_id)::numeric / COUNT(DISTINCT ip.policy_id), 4
    ) AS "Frequency"
FROM insurance_policy ip
    -- LEFT JOIN to count policies with 0 claims
    LEFT JOIN claim cl ON ip.policy_id = cl.policy_id
-- Ensures policy fully expired,
-- 150 days added to exclude RBNS (Reported but Not Settled claims reserve)
-- and IBNR (Incurred but Not Reported claim reserve) from calculations  
WHERE ip.end_date < NOW() - INTERVAL '150 days'
GROUP BY 
    ip.policy_type, 
    EXTRACT(YEAR FROM ip.end_date)
ORDER BY 
    "Line of Business",
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
        ip.policy_id,
        ip.start_date,
        ip.end_date,
         -- Total number of days in the policy period (+1 because both start and end dates are inclusive)
        (ip.end_date - ip.start_date) + 1 AS policy_period_days,  
        pp.period_start_date,
        pp.period_end_date,
        -- Start of overlap window (later of the two dates)
        GREATEST(ip.start_date,pp.period_start_date) AS overlap_start,
        -- End of overlap window (earlier of the two dates)
        LEAST(ip.end_date, pp.period_end_date) AS overlap_end
    FROM insurance_policy ip
    -- Attach period to each policy
    CROSS JOIN period_params pp
    -- Ensure there is at least 1 day overlap
    WHERE ip.start_date <= pp.period_end_date
        AND ip.end_date >= pp.period_start_date
),
calc_exposure AS(
    SELECT
        ip.policy_id,
        ip.premium_amount,
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
    JOIN insurance_policy ip USING (policy_id) -- JOIN tables by the same column
)
SELECT 
    ip.policy_type AS "Line of Business",
    COUNT(DISTINCT cl.claim_id) AS "Number of Claims",
    -- Exposure aggregated across all policies
    ROUND(SUM(exposure),2) AS "Total Exposure",
    -- Frequency = claims / exposure
    ROUND(COUNT(DISTINCT cl.claim_id) / SUM(exposure),4) AS "Frequency"
FROM calc_exposure ce
    LEFT JOIN claim cl ON cl.policy_id = ce.policy_id
        AND cl.accident_date >=  ce.period_start_date
        AND cl.accident_date <=  ce.period_end_date
    INNER JOIN insurance_policy ip ON ce.policy_id = ip.policy_id
GROUP BY ip.policy_type;

-- 9. Claim Severity (Total Loss / Number of Claims) by Line of Business and year
SELECT ip.policy_type AS "Line of Business",
    EXTRACT(YEAR FROM ip.end_date) AS year,
    -- Total paid losses
    SUM(cl.payout_amount) AS "Total Loss",
    COUNT(DISTINCT cl.claim_id) AS "Number of claims",
    -- Severity = Total Loss / Number of Claims
    ROUND(SUM(cl.payout_amount)::numeric / COUNT(DISTINCT cl.claim_id), 2) AS "Severity"
FROM insurance_policy ip
    LEFT JOIN claim cl ON ip.policy_id = cl.policy_id
-- Ensures policy fully expired,
-- 150 days added to exclude RBNS (Reported but Not Settled claims reserve)
-- and IBNR (Incurred but Not Reported claim reserve) from calculations 
WHERE ip.end_date < NOW() - INTERVAL '150 days'
GROUP BY 
    ip.policy_type,
    EXTRACT(YEAR FROM ip.end_date)
ORDER BY 
    "Line of Business", 
    year;

-- 10 Gross Premium Earned (GPE) per Line of Business, pro rata calculation (Common Table Expressions (CTE))
WITH period_params AS (
    SELECT 
        DATE '2025-01-01' AS period_start_date,
        DATE '2025-03-31' AS period_end_date
 ),
calc_overlap AS (
    SELECT
        ip.policy_id,
        ip.start_date,
        ip.end_date,
        -- Total number of days in the policy period (+1 because both start and end dates are inclusive)
        (ip.end_date - ip.start_date) + 1 AS policy_period_days,
        pp.period_start_date,
        pp.period_end_date,
        -- Start of overlap window (later of the two dates)
        GREATEST(ip.start_date,pp.period_start_date) AS overlap_start,
        -- End of overlap window (earlier of the two dates)
        LEAST(ip.end_date, pp.period_end_date) AS overlap_end
    FROM insurance_policy ip
        -- Attach period to each policy
        CROSS JOIN period_params pp
    -- Ensure there is at least 1 day overlap
    WHERE ip.start_date <= pp.period_end_date
        AND ip.end_date >= pp.period_start_date
),
premium_earned AS(
    SELECT
        ip.policy_id,
        ip.premium_amount,
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
        ip.premium_amount * ((co.overlap_end - co.overlap_start) +1) :: numeric / co.policy_period_days AS gross_premium_earned
    FROM calc_overlap co
        JOIN insurance_policy ip USING (policy_id) -- JOIN tables by the same column
)
SELECT 
    ip.policy_type AS "Line of Business",
    -- Aggregated GPE
    ROUND(SUM(pe.gross_premium_earned),2) AS "GPE"
FROM premium_earned pe, insurance_policy ip
WHERE pe.policy_id = ip.policy_id
GROUP BY ip.policy_type
ORDER BY "GPE" DESC;
