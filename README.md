# Insurance Data Mart — SQL & Data Engineering Portfolio Project

This project demonstrates the end-to-end design of a small **Insurance Data Mart**, including:
- Generation of high-quality **synthetic data** using Python + Faker  
- Creation of **dimensional data mart structures**  
- Analytical SQL queries for **GPE**, **exposure**, **frequency**, and **claims analysis**  
- Clean, production-ready SQL and Python scripts  
- A realistic workflow similar to BI / Data Engineering roles

This repository simulates the core analytical processes of an insurance company, including policies, customers, claims, pricing metrics, and exposure calculations.

---

## 🏗️ Project Overview

### 🎯 Goal  
Build a realistic insurance analytics environment using SQL and Python to demonstrate:

- Data generation  
- Data modelling  
- ETL logic  
- Insurance KPIs  
- SQL proficiency  
- Analytics workflows  

This project works with three core entities:
- **Customers**  
- **Policies**  
- **Claims**

---

## 🧬 Synthetic Data Generation

Data is generated using Python and the `Faker` library with realistic business logic:

### ✔️ `generate_customers.py`
- Creates customers with:
  - Name
  - DOB
  - Marital status
  - Number of children (realistic distribution)
  - Region (NZ regions)

### ✔️ `generate_policies.py`
- Assigns insurance policies to customers:
  - Policy type (Auto, House, Contents, Life…)
  - Start / end dates (exactly 1-year policies)
  - Premium amount (GPW)
  - Coverage amount

### ✔️ `generate_claims.py`
- Creates claims with:
  - Accident date (must fall within policy period)
  - Reporting date  
  - Claim status  
  - Claim amount  
  - Payout logic  
    - 0 for Rejected/Pending  
    - 80% Approved = full payout  
    - 20% Approved = partial payout  
---

## 🗄️ Data Mart Schema

`create_insurance_data_mart.sql` builds the full relational schema:

- **customer**
- **insurance_policy**
- **claim**
---

## 📊 Analytical SQL (analysis_queries.sql)

Includes insurance metrics and KPIs:

### **📌 Gross Premium Earned (GPE)**
- Accurate day-level overlap calculation  
- Handles partial policy periods  
- Supports custom intervals (e.g., Q1 2025)

### **📌 Exposure Calculation**
- Overlapping policy days / full policy duration  
- Used for rate making and frequency

### **📌 Frequency**



