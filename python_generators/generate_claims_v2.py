from faker import Faker
from datetime import timedelta
import pandas as pd
import numpy as np
import random

def random_date_within(start_date, end_date):
    """
    Generate a random date between two dates (inclusive).
    """
    delta_days = (end_date - start_date).days
    random_days = random.randint(0, delta_days)
    return start_date + timedelta(days=random_days)

# Number of claims (~20% of the number of policies)
def generate_claims(n_claims=2500, seed=42):
    """
    Generate synthetic insurance claims data.
    
    Creates approximately 20% claims relative to the number of policies.
    Each claim is assigned one of three statuses with different probabilities:
        - Status 1 (Approved): 60% - includes settlement and payout dates
        - Status 2 (Pending): 25% - no settlement or payout yet
        - Status 3 (Rejected): 15% - settled but no payout
    
    Args:
        n_claims: Number of claims to generate (default: 2500)
        seed: Random seed for reproducibility (default: 42)
    """
    # Initialize random generators
    fake = Faker()
    fake.seed_instance(seed)
    random.seed(seed)

    # Load reference data
    df_policies = pd.read_csv("FactPolicies(with_id).csv")
    df_claim_status = pd.read_csv("DimClaimStatus(with_id).csv")
    df_policies['start_date'] = pd.to_datetime(df_policies['start_date'], format="%Y-%m-%d")
    df_policies['end_date'] = pd.to_datetime(df_policies['end_date'], format="%Y-%m-%d")

    # Define data generation cutoff date
    cutoff_date = pd.Timestamp(2025, 8, 31)
    
    # Define parameters claim amount distribution
    mean = 7.5
    sigma = 0.9
    
    # Pre-filter policies that started before cutoff
    valid_policies = df_policies[df_policies['start_date'] <= cutoff_date]
    
    # Claim status 
    claim_status_ids = df_claim_status['claim_status_id'].tolist()

    claims = []

    for claim_id in range(1, n_claims + 1):
        # Randomly select a policy
        policy_row = valid_policies.sample(n=1).iloc[0]
        policy_id = policy_row['policy_id']
        policy_start = pd.to_datetime(policy_row['start_date'], format="%Y-%m-%d")
        policy_end = pd.to_datetime(policy_row['end_date'], format="%Y-%m-%d")
        policy_coverage = policy_row['coverage_amount']
        
        # Determine claim status with weighted probability
        status_id = random.choices(claim_status_ids, weights=[0.6, 0.25, 0.15])[0]
        
        # Generate claim amount
        #claim_amount = round(random.uniform(200, 20000), 2)
        amount = np.random.lognormal(mean, sigma)
        claim_amount = round(min(max(amount, 200), 20000), 2)

        # Calculate the effective end date for claim occurrence
        effective_end_date = min(policy_end, cutoff_date)

        # Generate claim occurrence date within policy period
        occurred_date = random_date_within(policy_start, effective_end_date)
        # Reported 0-90 days after occurrence
        reported_date =  occurred_date + timedelta(days=random.randint(0, 90))   

        # Initialize variables
        settled_date = None
        paid_date = None
        payout_amount = 0.0

        if status_id == 1:  # Approved
            # Settlement occurs 3-14 days after reporting
            settled_date = reported_date + timedelta(days=random.randint(3, 14))
            
            # Payment occurs 0-3 days after settlement
            paid_date = settled_date + timedelta(days=random.randint(0, 3))
            
            # Determine payout amount (80% full payment, 20% partial)
            if random.random() <= 0.8:
                payout_amount = claim_amount
            else:
                # Partial payment: 50-99% of claim amount
                payout_amount = round(claim_amount * random.uniform(0.5, 0.99), 2)
        elif status_id == 3:  # Rejected
            # Rejection decision made 3-14 days after reporting
            settled_date = reported_date + timedelta(days=random.randint(3, 14))
            # paid_date remains None, payout_amount remains 0.0

        # STATUS_PENDING: Settled and paid dates remain None, payout_amount 0.0
        
        # Payout cannot exceed policy coverage
        payout_amount = min(policy_coverage, payout_amount)
        
        # Append claim record
        claims.append({
            "policy_id": policy_id,
            "occurred_date":  occurred_date,
            "reported_date": reported_date,
            "settled_date": settled_date,
            "paid_date": paid_date,
            "claim_amount": claim_amount,
            "claim_status_id": status_id,
            "payout_amount": payout_amount
        })
    
    # Create DataFrame and export to CSV
    df = pd.DataFrame(claims)
    df.to_csv("FactClaims.csv", index=False)
    print("FactClaims.csv generated successfully!")

if __name__ == "__main__":
    generate_claims()
