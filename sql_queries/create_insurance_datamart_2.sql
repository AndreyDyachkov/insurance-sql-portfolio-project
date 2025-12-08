-- ===========================
-- 1. DROP TABLES (IF EXIST)
-- ===========================

DROP TABLE IF EXISTS DimRegion;
DROP TABLE IF EXISTS DimCustomer;
DROP TABLE IF EXISTS DimPolicyType;
DROP TABLE IF EXISTS DimProduct;
DROP TABLE IF EXISTS DimClaimStatus;
DROP TABLE IF EXISTS FactPolicies;
DROP TABLE IF EXISTS FactClaims;

-- ===========================
-- 2. CREATE TABLES
-- ===========================
--  DimRegion
CREATE TABLE DimRegion (
region_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
region_name TEXT UNIQUE NOT NULL
);

--  DimCustomer
CREATE TABLE DimCustomer (
customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
region_id INT,
full_name TEXT NOT NULL,
date_of_birth DATE NOT NULL,
marital_status TEXT CHECK (marital_status IN ('Single','Married')),
FOREIGN KEY (region_id) REFERENCES DimRegion(region_id)
);

--  DimPolicyType
CREATE TABLE DimPolicyType (
policy_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
policy_type_name TEXT UNIQUE NOT NULL
);

--  DimProduct
CREATE TABLE DimProduct (
product_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
policy_type_id INT,
product_name TEXT UNIQUE NOT NULL,
FOREIGN KEY (policy_type_id) REFERENCES DimPolicyType(policy_type_id)
);
--  DimClaimStatus
CREATE TABLE DimClaimStatus (
claim_status_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
status_name TEXT UNIQUE NOT NULL
);

--  FactPolicies
CREATE TABLE FactPolicies (
    policy_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT,
	product_id INT,
	policy_number TEXT UNIQUE NOT NULL,
	start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    premium_amount NUMERIC(12,2),
	coverage_amount NUMERIC(12,2),
	FOREIGN KEY (customer_id) REFERENCES DimCustomer(customer_id),
	FOREIGN KEY (product_id) REFERENCES DimProduct
);

--  FactClaims
CREATE TABLE FactClaims(
    claim_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    policy_id INT,
	occurred_date DATE,
    reported_date DATE,
	settled_date DATE,
	paid_date DATE,
    claim_amount NUMERIC(12,2),
    claim_status_id INT,
    payout_amount DECIMAL(12,2),
    FOREIGN KEY (policy_id) REFERENCES FactPolicies(policy_id),
	FOREIGN KEY (claim_status_id) REFERENCES DimClaimStatus(claim_status_id)
);
-- ===========================
-- 3. INSERT DATA
-- ===========================
--  DimPolicyType
INSERT INTO DimPolicyType (policy_type_name) VALUES
('Health'),
('Home'),
('Motor'),
('Travel');

--  DimProduct
INSERT INTO DimProduct (policy_type_id, product_name) VALUES
(1, 'Basic Health Cover'),
(1, 'Premium Health Cover'),
(2, 'Home Standard'),
(2, 'Home Comprehensive'),
(3, 'Motor Third-Party'),
(3, 'Motor Fully Comprehensive'),
(4, 'Travel Single Trip'),
(4, 'Travel Annual Multi-Trip');

--  DimClaimStatus
INSERT INTO DimClaimStatus (status_name) VALUES
('Approved'),
('Pending'),
('Rejected');

--  DimRegion, DimCustomer, FactPolicies, FactClaims - import Python script generated sample data from CSV
