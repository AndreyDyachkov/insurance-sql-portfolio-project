from faker import Faker
from datetime import datetime, timedelta
import pandas as pd
import random


def random_date_within(policy_start_date, policy_end_date):
    """Generate random date between two dates (inclusive)."""
    start_date = datetime.strptime(policy_start_date, "%d/%m/%Y")
    end_date = datetime.strptime(policy_end_date, "%d/%m/%Y")
    
    delta_days = (end_date - start_date).days
    random_days = random.randint(0, delta_days)
    return (start_date + timedelta(days=random_days)).date()

def generate_claims(n_claims=2500, seed=42):
    fake = Faker()
    fake.seed_instance(seed)
    random.seed(seed)

    policies_df = pd.read_csv("policies.csv")
    
    claim_statuses = ["Approved", "Rejected", "Pending"]

    claims = []

    for claim_id in range(1, n_claims + 1):
        policy_row = policies_df.sample(n=1).iloc[0]
        policy_id = policy_row['policy_id']
        policy_start = policy_row['start_date']
        policy_end = policy_row['end_date']

        accident_date = random_date_within(policy_start, policy_end)
        reporting_date =  accident_date + timedelta(days=random.randint(0, 150))
                
        status = random.choices(claim_statuses, weights=[0.6, 0.25, 0.15])[0]
        claim_amount = round(random.uniform(500, 200000), 2)
        
        # Calculate payout_amount based on status
        if status in ["Rejected", "Pending"]:
            payout_amount = 0
        else:  # Approved
            if random.random() <= 0.8:  # 80% of approved claims are fully paid
                payout_amount = claim_amount
            else:
                # partially paid claim: random between 50% and 99%
                payout_amount = round(claim_amount * random.uniform(0.5, 0.99), 2)

        claims.append({
            "claim_id": claim_id,
            "policy_id": policy_id,
            "accident_date":  accident_date,
            "reporting_date": reporting_date,
            "claim_amount": claim_amount,
            "claim_status": status,
            "payout_amount": payout_amount
        })

    df = pd.DataFrame(claims)
    df.to_csv("claims.csv", index=False)
    print("claims.csv generated")

if __name__ == "__main__":
    generate_claims()
