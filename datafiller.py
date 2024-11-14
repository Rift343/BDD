import psycopg2
from faker import Faker
import random
from datetime import datetime, timedelta


"""
Data filler in python for the database
    Made using ChatGPT
    Dometimes the datafiller will fail, when so random number gets drawn twice
    in that case, run it a sencond time
    
    """



# Initialize Faker instance
fake = Faker()

# Database connection
conn = psycopg2.connect(
    dbname="DATA_BASE_API",
    user="API_ADMIN",
    password="gfityf_voul_4586",
    host="localhost",
    port="5432"
)
cur = conn.cursor()

# Insert Functions for Each Table

def insert_entities(num_records=100):
    for _ in range(num_records):
        # Generate fake data with length constraints
        swift_id = fake.unique.bban()[:10]  # Truncate to 10 characters
        entity_name = fake.company()[:20]  # Limit EntityName to 20 characters
        bic = fake.swift11()[:11]  # SWIFT BIC is up to 11 characters
        address = fake.address()[:20]  # Limit Address to 20 characters
        country = fake.country()[:20]  # Country name within 20 characters
        year_of_joining_swift = fake.year()
        legal_jurisdiction = fake.country()[:20]  # Limit to 20 characters
        email = fake.email()[:20]  # Limit Email to 20 characters
        phone_number = fake.phone_number()[:20]  # Limit PhoneNumber to 20 characters
        fraud_prevention_contact = fake.name()[:20]  # Limit to 20 characters
        beneficial_owner = fake.name()[:20]  # Limit BeneficialOwner to 20 characters
        language = fake.language_name()[:20]  # Limit Language to 20 characters
        business_entity_type = random.choice(['Corporate', 'State Owned', 'Privately Owned', 'Publicly Owned'])[:20]
        isic_code = fake.isbn10()[:10]  # Limit ISICCode to 10 characters
        legal_entity_identifier = fake.ean(length=13)[:13]  # Limit LegalEntityIdentifier to 13 characters
        naics_code = "eee"[:10]  # Example with truncation to 10 characters
        oid_id = "eeeee"[:10]  # Example with truncation to 10 characters

        # Prepare SQL query and data
        sql_query = """
            INSERT INTO Entities (SwiftID, EntityName, BIC, Address, Country, YearOfJoiningSWIFT,
                                  LegalJurisdiction, Email, PhoneNumber, FraudPreventionContact,
                                  BeneficialOwner, Language, BusinessEntityType, ISICCode,
                                  LegalEntityIdentifier, NAICSCode, OIDID)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
        data = (
            swift_id,
            entity_name,
            bic,
            address,
            country,
            year_of_joining_swift,
            legal_jurisdiction,
            email,
            phone_number,
            fraud_prevention_contact,
            beneficial_owner,
            language,
            business_entity_type,
            isic_code,
            legal_entity_identifier,
            naics_code,
            oid_id
        )

        # Print the query and data for debugging
        print("Executing SQL query:", sql_query % data)

        # Execute the query with data
        cur.execute(sql_query, data)


def insert_date_dimension(start_date, num_days=365):
    # Ensure start_date is not before January 1, 2021
    if start_date < datetime(2021, 1, 1):
        start_date = datetime(2021, 1, 1)
    
    # Calculate end date, and limit it to today if it exceeds
    end_date = min(start_date + timedelta(days=num_days), datetime.today())
    
    current_date = start_date
    while current_date <= end_date:
        cur.execute("""
            INSERT INTO Date (FullDate, Year, Month, Day, FiscalYear, Holiday, DayOfWeek, Quarter)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
            current_date,
            current_date.year,
            current_date.month,
            current_date.day,
            current_date.year,  # Assuming fiscal year aligns with calendar year
            fake.boolean(chance_of_getting_true=10),  # 10% chance of being a holiday
            current_date.strftime('%A'),
            (current_date.month - 1) // 3 + 1
        ))
        current_date += timedelta(days=1)  # Increment to the next day

def insert_time_dimension(num_records=150000):
    for _ in range(num_records):
        # Ensure start_date and end_date are datetime objects
        start_date = datetime(2021, 1, 1)  # 2021-01-01 as a datetime object
        end_date = datetime.now()  # Current datetime

        # Generate a random datetime between start_date and end_date
        time = fake.date_time_between(start_date=start_date, end_date=end_date)

        # Prepare and execute the SQL query
        cur.execute("""
            INSERT INTO Time (CompleteTime, AM_PM, Hour, Minute, Second, Format12H, TimeZone)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
            time,
            'AM' if time.hour < 12 else 'PM',
            time.hour,
            time.minute,
            time.second,
            fake.boolean(),  # Format12H
            random.choice(['UTC', 'EST', 'CST', 'MST', 'PST'])  # Random timezone
        ))

def insert_transaction_type(num_records=3500):
    for _ in range(num_records):
        cur.execute("""
            INSERT INTO TransactionType (TransactionName, TransactionType, Description, Category,
                                         Status, TaxRate, CategoryTime, IsTransfer, IsRecurring, IsAutomated)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
            fake.job()[:50],  # Example job title or placeholder for transaction name
            random.choice(['MT103', 'MT202', 'MT940', 'MT900', 'MT910']),  # SWIFT transaction types
            fake.text(),
            random.choice(['Payments', 'Reconciliation', 'Reporting', 'Settlement']),  # SWIFT-related categories
            random.choice(['Pending', 'Completed', 'Failed', 'Rejected']),  # Status options
            round(random.uniform(0, 30), 2),  # TaxRate
            random.choice(['Realtime', 'Neartime', 'T+1', 'T+X']),  # SWIFT category timesRealtime', 'Neartime', 'T', 'T+1', 'T+X'
            fake.boolean(),  # IsTransfer
            fake.boolean(),  # IsRecurring
            fake.boolean()   # IsAutomated
        ))

def insert_asset(num_records=50):
    for _ in range(num_records):
        cur.execute("""
            INSERT INTO Asset (AssetType, AssetName, UnitDivisibility, CountryOfOrigin,
                               LegalStatus, ExchangeRateToUSD, IssuerOrganizationName,
                               IsPubliclyTraded, IsPreciousMetal, ISIN)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
            random.choice(['Currency', 'Security']),
            fake.currency_name(),
            round(random.uniform(0.0001, 1), 8),
            fake.country(),
            fake.boolean(),
            round(random.uniform(0.5, 100), 8),
            fake.company(),
            fake.boolean(),
            fake.boolean(),
            fake.isbn13()[12:]
        ))

def insert_server(num_records=20):
    for _ in range(num_records):
        cur.execute("""
            INSERT INTO Server (ServerName, IPAddress, Location, Cluster, OperatingSystem,
                                CPUCores, MemoryCapacity, ECCMemory, StorageCapacity, NetworkBandwidth,
                                Manufacturer, ServerRole, Environment)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
            fake.hostname(),
            fake.ipv4(),
            fake.city(),
            fake.word(),
            random.choice(['MS', 'linux', 'openbsd']),
            random.randint(2, 32),  # CPU cores
            random.randint(8, 256),  # Memory in GB
            fake.boolean(),
            random.randint(128, 4096),  # Storage in GB
            random.randint(10, 1000),  # Network bandwidth in Mbps
            fake.company(),
            fake.job(),
            random.choice(['Production', 'Test', 'Development'])
        ))

def insert_service(num_records=50):
    for _ in range(num_records):
        cur.execute("""
            INSERT INTO Service (ServiceName, ServiceType, CriticalityLevel, Description,
                                 IsRedundant, Vendor, Environment, CybersecurityExposure, IsPubliclyAccessible)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
            fake.bs(),
            fake.job(),
            random.choice(['High', 'Medium', 'Low']),
            fake.text(),
            fake.boolean(),
            fake.company(),
            random.choice(['Production', 'Test', 'Development']),
            fake.text(),
            fake.boolean()
        ))

def insert_messages(num_records=100000):
    for _ in range(num_records):
        cur.execute("""
            INSERT INTO Messages (TransactionTypeID, AssetID, Content, DateID, TimeID,
                                  EntitySenderID, EntityReceiverID, Amount)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
            random.randint(1, 50),  # TransactionTypeID
            random.randint(1, 50),  # AssetID
            fake.text(),
            random.randint(1, 365),  # DateID
            random.randint(1, 1000),  # TimeID
            random.randint(1, 100),  # EntitySenderID
            random.randint(1, 100),  # EntityReceiverID
            round(random.uniform(10, 10000), 2)
        ))

def insert_incident(num_records=5000):
    for _ in range(num_records):
        cur.execute("""
            INSERT INTO Incident (ServerID, ServiceID, DateID, TimeID, IncidentDuration, Description)
            VALUES (%s, %s, %s, %s, %s, %s)
            """, (
            random.randint(1, 20),  # ServerID
            random.randint(1, 50),  # ServiceID
            random.randint(1, 365),  # DateID
            random.randint(1, 1000),  # TimeID
            timedelta(minutes=random.randint(1, 1440)),  # Incident duration up to 24 hours
            fake.text()
        ))

# Main function to populate tables
def populate_database():
    insert_entities()
    insert_date_dimension(datetime.now() - timedelta(days=365))
    insert_time_dimension()
    insert_transaction_type()
    insert_asset()
    insert_server()
    insert_service()
    insert_messages()
    insert_incident()
    conn.commit()

populate_database()
cur.close()
conn.close()
