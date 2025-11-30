from faker import Faker
import pandas as pd
import random

def num_children(is_married):
    """
    If single: mostly 0 children.
    If married: normal family distribution.
    """
    if not is_married:
        return random.choices(
            population=[0, 1, 2],
            weights=[0.85, 0.12, 0.03],
            k=1
        )[0]

    return random.choices(
        population=[0, 1, 2, 3, 4],
        weights=[0.30, 0.35, 0.25, 0.08, 0.02],
        k=1
    )[0]

def generate_customers(n_customers=3000, seed=42):
    fake = Faker("en_NZ")
    fake.seed_instance(seed)
    random.seed(seed)

    customers = []

    regions = [
        "Auckland", "Wellington", "Canterbury", "Waikato",
        "Bay of Plenty", "Otago", "Manawatu-Whanganui",
        "Northland", "Taranaki", "Hawke's Bay", "Southland"
    ]

    for customer_id in range(1, n_customers + 1):
        married = fake.boolean(chance_of_getting_true=55)
        customers.append({
            "customer_id": customer_id,
            "full_name": fake.name(),
            "dob": fake.date_of_birth(minimum_age=18, maximum_age=80),
            "marital_status": "Married" if married else "Single",
            "num_children": num_children(married),
            "region":random.choice(regions)
        })

    df = pd.DataFrame(customers)
    df.to_csv("customers.csv", index=False)
    print("customers.csv generated")

if __name__ == "__main__":
    generate_customers()
