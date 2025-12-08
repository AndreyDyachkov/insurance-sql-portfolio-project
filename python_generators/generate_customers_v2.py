from faker import Faker
import pandas as pd
import random

def generate_customers(n_customers=6000, seed=42):
    """
    Generate synthetic customer data for the DimCustomer table and save to CSV.

    Parameters
    ----------
    n_customers : int
        Number of customers to generate.
    seed : int
        Random seed for reproducibility.
    """
    # Initialize Faker and random seed
    fake = Faker("en_NZ")
    fake.seed_instance(seed)
    random.seed(seed)

    # Load regions from existing DimRegion CSV
    # The CSV must contain: region_id, region_name
    df_regions = pd.read_csv('DimRegion(with_id).csv')
    region_ids = df_regions['region_id'].tolist()

    customers = []
    
    # Generate customer records
    for customer_id in range(1, n_customers + 1):
        
        # 55% probability of marital status being Married
        married = fake.boolean(chance_of_getting_true=55)
                
        customers.append({
            "region_id": random.choice(region_ids),
            "full_name": fake.name(),
            "date_of_birth": fake.date_of_birth(minimum_age=21, maximum_age=80),
            "marital_status": "Married" if married else "Single",
        })

    # Convert to DataFrame and export
    df = pd.DataFrame(customers)
    df.to_csv("DimCustomer.csv", index=False)
    print("DimCustomer.csv generated successfully!")

if __name__ == "__main__":
    generate_customers()
