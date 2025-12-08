from faker import Faker
from dateutil.relativedelta import relativedelta
from datetime import timedelta
import pandas as pd
import numpy as np
import random

def generate_premium():
    """
    Generate a realistic premium amount using a lognormal distribution.
    Premiums are constrained within reasonable insurance premium limits.
    """
    premium = np.random.lognormal(mean=6.4, sigma=0.6)
    premium = min(max(premium, 200), 5000)
    return round(premium, 2)

def generate_policy_number(policy_id, policy_type_id, start_date):
    """
    Generate a readable policy number in the format:
    PREFIX-YEAR-0000001
    
    Prefix is based on policy type:
        1 = Health  (HLT)
        2 = Home    (HOM)
        3 = Motor   (MTR)
        4 = Travel  (TRV)
    """
    policy_type_prefix = {1: "HLT", 2: "HOM", 3: "MTR", 4: "TRV"}
    prefix = policy_type_prefix.get(policy_type_id, "GEN")
    year = start_date.year
    return f"{prefix}-{year}-{policy_id:07d}"

def generate_policies(n_policies=12000, seed=42):
    """
    Generate synthetic FactPolicy data using:
    - Customer IDs from DimCustomer
    - Product IDs + their policy types from DimProduct
    - Random start/end dates (1-year duration)
    - Lognormal premiums
    - Policy numbers linked to policy type
    """
    fake = Faker()
    fake.seed_instance(seed)
    random.seed(seed)

    # Load dimension tables
    df_customers = pd.read_csv("DimCustomer(with_id).csv")        
    df_products  = pd.read_csv("DimProduct(with_id).csv")
    
    # Build lookup dictionary: product_id → policy_type_id
    # Ensures product and policy_type always match
    product_lookup = df_products.set_index("product_id")["policy_type_id"].to_dict()

    # List of available IDs for random selection
    customer_ids = df_customers["customer_id"].tolist()
    product_ids = list(product_lookup.keys())  # available product IDs
    
    policies = []

    for policy_id in range(1, n_policies + 1):
        # Pick customer and product
        customer_id = random.choice(customer_ids)
        product_id = random.choice(product_ids)

        # Derive policy_type_id from product table
        policy_type_id = product_lookup[product_id]

        # Random policy start date within last 3 years
        start_date = fake.date_between(start_date="-3y", end_date="-1d")
        
        # 1 year duration (use relativedelta to handle leap years)
        end_date = start_date + relativedelta(years=1) - timedelta(days=1)

        # Generate policy number
        policy_number = generate_policy_number(policy_id, policy_type_id, start_date)

        premium_amount = generate_premium()
        coverage_amount = round(premium_amount * random.uniform(5, 50), 2)

        policies.append({
            "customer_id": customer_id,
            "product_id": product_id,
            "policy_number":policy_number,
            "start_date": start_date,
            "end_date": end_date,
            "premium_amount": premium_amount,
            "coverage_amount": coverage_amount
        })

    df = pd.DataFrame(policies)
    df.to_csv("FactPolicies.csv", index=False)
    print("FactPolicy.csv generated successfully!")
    
if __name__ == "__main__":
    generate_policies()
