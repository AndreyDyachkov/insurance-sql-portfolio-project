# Insurance Data Mart — SQL & Data Engineering Portfolio Project

This repository simulates the core analytical processes of an insurance company, including policies, customers, claims, insurance metrics, and KPIs.
The project demonstrates the end-to-end design of a small **Insurance Data Mart**, including:
- Generation of realistic **synthetic data** using Python + Faker;
- Creation of **dimensional data mart structures**;  
- Analytical SQL queries for insurance metrics and KPIs: **Gross Premium Written(GPW)**, **Gross Premium Earned(GPE)**, **exposure**, **frequency**, and **claims analysis**;
- Production-ready SQL scripts.

---

## 📁 Repository Structure
```
insurance-sql-portfolio-project/
├── python_generators/
│   ├── generate_customers_v2.py
│   ├── generate_policies_v2.py
│   └── generate_claims_v2.py
├── sql_queries/
│   ├── create_insurance_data_mart_2.sql
│   └── analysis_queries_v2.sql
├── sample_data/
│   ├── DimClaimStatus(with_id).csv
│   ├── DimCustomer(with_id).csv
│   ├── DimPolicyType(with_id).csv
│   ├── DimProduct(with_id).csv
│   ├── DimRegion(with_id).csv
│   ├── FactClaims(with_id).csv
│   └── FactPolicies(with_id).csv
└── README.md
```

## 🏗️ Project Overview

### 🎯 Goal  
Demonstrate practical data engineering and SQL analytics skills by:
- Building a realistic insurance data pipeline from scratch;
- Implementing dimensional modeling best practices;
- Calculating industry-standard insurance KPIs;
- Writing well-structured, documented SQL scripts.

## 🧬 Synthetic Data Generation
Data is generated using Python and the `Faker` library with realistic business logic:

### ✔️ `generate_customers.py`
- Creates customers with:
  - Name;
  - Date of birth;
  - Marital status;
  - Region (NZ regions).

### ✔️ `generate_policies.py`
- Assigns insurance policies to customers:
  - Policy number;
  - Product (Basic Health Cover, Premium Health Cover, etc.) and Line of Business (Health, Travel, etc.);
  - Start and end dates;
  - Premium amount (GPW);
  - Coverage amount.

### ✔️ `generate_claims.py`
- Creates realistic claims with:
  - Claim ID and policy reference;
  - Occurred date (validated to fall within policy period);
  - Reporting date (after occurred date);
  - Settled date for Approved and Rejected claims ((null for Pending);
  - Claim status (Approved, Pending, Rejected); 
  - Claim amount (follows lognormal distribution); 
  - Payout logic: 
    - 0 for Rejected/Pending claims;  
    - 80% of Approved claims receive full payout within coverage limit; 20% receive partial payout.

---

## 🗄️ Data Mart Schema

`create_insurance_data_mart_2.sql` builds the full relational schema:

#### ER Diagram
<img src="ER_diagram_v2.png"  width="800">

#### Relational Schema
<img src="Relational_schema_v2.png" width="800">

---

## 📊 Analytical SQL (analysis_queries_v2.sql)

Includes insurance metrics and KPIs:
### **📌 Annual Gross Premium Written (GPW) by Line of Business (LOB)**
- A typical insurance KPI for estimating sales by LOB;
- Other intervals (monthly, quarterly) can be applied as well.

### **📌 Running Total of Monthly GPW by Year (Common Table Expression (CTE) + Window Function)**
- Common insurance KPI for estimating YTD (Year-to-Date) sales;
- SQL query includes a CTE to aggregate sales by month and year, and a window function to calculate running total.

### **📌 Customer Analytics (Nested Queries, Window Function)**
Includes various typical analytical tasks:
- Ranking Customers by Lifetime Net Value (LTV);
- Customers with More Than 2 Claims per Policy (Nested Query);
- Customers with More Than 2 Claims in the Past Year;
- Top 3 Customers by Payout Amount.

### **📌 Frequency Calculation (Common Table Expression (CTE))**
Claim frequency calculation is one of the main tasks in insurance analytics, used for premium pricing.
- Claim Frequency for Expired Policies by Product, LOB and Year;  
- Exposure-Based Frequency for a specific reporting period.

### **📌 Claim Severity by LOB and Year**
Severity is the average cost per claim, also used for premium pricing.

### **📌 Gross Premium Earned (GPE) per LOB (Common Table Expressions (CTE))**
- Accurate day-level overlap calculation; 
- Handles partial policy periods; 
- Supports custom intervals (e.g., Q1 2025).

## 🧩 SQL Queries
Full scripts are available in:
- [`create_insurance_data_mart_2.sql`](create_insurance_data_mart.sql)  
- [`analysis_queries_v2.sql`](https://github.com/AndreyDyachkov/insurance-sql-portfolio-project/blob/main/sql_queries/analysis_queries_v2.sql)

---

## 📋 Prerequisites
- Python 3.8+
- PostgreSQL
- Required Python packages: `faker`, `pandas`, `numpy`, `random`

## 💻 Usage
1. Clone the repository;
2. Install dependencies: `pip install faker` and run data generation scripts to generate sample data OR use ready-made sample data;
4. Execute SQL scripts to create the data mart, upload sample data;
5. Run analytical queries.
