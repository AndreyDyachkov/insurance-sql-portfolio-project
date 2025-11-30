-- ===========================
-- 1. DROP TABLES (IF EXIST)
-- ===========================
DROP TABLE IF EXISTS claim;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS insurance_policy;

-- ===========================
-- 2. CREATE TABLES
-- ===========================
-- Customer Dimension
CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    dob DATE,
    marital_status VARCHAR(20),
    num_children INT,
    region VARCHAR(50)
);
-- Policy Dimension
CREATE TABLE insurance_policy (
    policy_id INT PRIMARY KEY,
    customer_id INT,
	policy_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    premium_amount DECIMAL(12,2),
	coverage_amount DECIMAL(12,2),
	FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);
-- Claims Fact Table
CREATE TABLE claim (
    claim_id INT PRIMARY KEY,
    policy_id INT,
    accident_date DATE,
	reporting_date DATE,
    claim_amount DECIMAL(12,2),
    claim_status VARCHAR(20),
    payout_amount DECIMAL(12,2),
    FOREIGN KEY (policy_id) REFERENCES insurance_policy(policy_id)
);