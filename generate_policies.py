from faker import Faker
from dateutil.relativedelta import relativedelta
from datetime import timedelta
import pandas as pd
import random

def generate_policies(n_policies=6000, seed=42):
    fake = Faker()
    fake.seed_instance(seed)
    random.seed(seed)

    customers = pd.read_csv("customers.csv")
    customer_ids = customers["customer_id"].tolist()

    policy_types = ["Health", "Life", "Motor", "Home"]
    
    policies = []

    for policy_id in range(1, n_policies + 1):
        start_date = fake.date_between(start_date="-3y", end_date="today")

        policies.append({
            "policy_id": policy_id,
            "customer_id": random.choice(customer_ids),
            "policy_type": random.choice(policy_types),
            "start_date": start_date,
            "end_date": start_date + relativedelta(years=1) - timedelta(days=1),  # relativedelta - to deal with leap years
            "premium_amount": round(random.uniform(200, 3000), 2),
            "coverage_amount": round(random.uniform(20000, 300000), 2)
        })

    df = pd.DataFrame(policies)
    df.to_csv("policies.csv", index=False)
    print("policies.csv generated")

if __name__ == "__main__":
    generate_policies()
