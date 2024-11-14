CREATE ROLE postgres WITH LOGIN PASSWORD 'gfityf_voul_4586';
CREATE ROLE API_ADMIN WITH LOGIN PASSWORD 'gfityf_voul_4586';

CREATE DATABASE DATA_BASE_API OWNER API_ADMIN;
-- Database schema for Action 1 and Action 2 dimensions

-- Action 1 Dimensions

-- Dimension: Entities
CREATE TABLE Entities (
    EntityID SERIAL PRIMARY KEY,
    SwiftID VARCHAR(20) UNIQUE NOT NULL,
    EntityName VARCHAR(100) NOT NULL,
    BIC CHAR(11) UNIQUE,
    Address TEXT,
    Country VARCHAR(50),
    YearOfJoiningSWIFT INT CHECK (YearOfJoiningSWIFT BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    LegalJurisdiction VARCHAR(50),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(20),
    FraudPreventionContact VARCHAR(100),
    BeneficialOwner VARCHAR(100),
    Language VARCHAR(50),
    BusinessEntityType VARCHAR(20) CHECK (BusinessEntityType IN ('Corporate', 'State Owned', 'Privately Owned', 'Publicly Owned')),
    ISICCode VARCHAR(10),
    LegalEntityIdentifier VARCHAR(20) UNIQUE,
    NAICSCode VARCHAR(10),
    OIDID VARCHAR(20)
);

-- Dimension: Date
CREATE TABLE Date (
    DateID SERIAL PRIMARY KEY,
    FullDate DATE NOT NULL UNIQUE,
    Year INT,
    Month INT CHECK (Month BETWEEN 1 AND 12),
    Day INT CHECK (Day BETWEEN 1 AND 31),
    FiscalYear INT,
    Holiday BOOLEAN,
    DayOfWeek VARCHAR(10),
    Quarter INT CHECK (Quarter BETWEEN 1 AND 4)
);

-- Dimension: Time
CREATE TABLE Time (
    TimeID SERIAL PRIMARY KEY,
    CompleteTime TIME NOT NULL,
    AM_PM CHAR(2) CHECK (AM_PM IN ('AM', 'PM')),
    Hour INT CHECK (Hour BETWEEN 0 AND 23),
    Minute INT CHECK (Minute BETWEEN 0 AND 59),
    Second INT CHECK (Second BETWEEN 0 AND 59),
    Format12H BOOLEAN, -- TRUE for 12-hour format, FALSE for 24-hour
    TimeZone VARCHAR(10)
);

-- Dimension: TransactionType
CREATE TABLE TransactionType (
    TransactionID SERIAL PRIMARY KEY,
    TransactionName VARCHAR(50),
    TransactionType VARCHAR(50),
    Description TEXT,
    Category VARCHAR(50),
    Status VARCHAR(20),
    TaxRate DECIMAL(5, 2),
    CategoryTime VARCHAR(20) CHECK (CategoryTime IN ('Realtime', 'Neartime', 'T', 'T+1', 'T+X')),
    IsTransfer BOOLEAN,
    IsRecurring BOOLEAN,
    IsAutomated BOOLEAN
);

-- Dimension: Asset
CREATE TABLE Asset (
    AssetID SERIAL PRIMARY KEY,
    AssetType VARCHAR(20) CHECK (AssetType IN ('Currency', 'Security')),
    AssetName VARCHAR(50),
    UnitDivisibility DECIMAL(18, 8), -- Support for divisibility in financial assets
    CountryOfOrigin VARCHAR(50),
    LegalStatus BOOLEAN, -- TRUE if allowed to trade, FALSE otherwise
    ExchangeRateToUSD DECIMAL(18, 8),
    IssuerOrganizationName VARCHAR(100),
    IsPubliclyTraded BOOLEAN,
    IsPreciousMetal BOOLEAN,
    ISIN CHAR(12) UNIQUE
);

-- Action 2 Dimensions

-- Dimension: Server
CREATE TABLE Server (
    ServerID SERIAL PRIMARY KEY,
    ServerName VARCHAR(100),
    IPAddress INET UNIQUE,
    Location VARCHAR(100),
    Cluster VARCHAR(50),
    OperatingSystem VARCHAR(50),
    CPUCores INT CHECK (CPUCores > 0),
    MemoryCapacity INT CHECK (MemoryCapacity > 0), -- in GB
    ECCMemory BOOLEAN,
    StorageCapacity INT CHECK (StorageCapacity > 0), -- in GB
    NetworkBandwidth INT CHECK (NetworkBandwidth > 0), -- in Mbps
    Manufacturer VARCHAR(50),
    ServerRole VARCHAR(50),
    Environment VARCHAR(20) CHECK (Environment IN ('Production', 'Test', 'Development'))
);

-- Dimension: Service
CREATE TABLE Service (
    ServiceID SERIAL PRIMARY KEY,
    ServiceName VARCHAR(100),
    ServiceType VARCHAR(50),
    CriticalityLevel VARCHAR(10) CHECK (CriticalityLevel IN ('High', 'Medium', 'Low')),
    Description TEXT,
    IsRedundant BOOLEAN,
    Vendor VARCHAR(50),
    Environment VARCHAR(20) CHECK (Environment IN ('Production', 'Test', 'Development')),
    CybersecurityExposure TEXT,
    IsPubliclyAccessible BOOLEAN
);

CREATE TABLE Messages (
    FactID SERIAL PRIMARY KEY,
    TransactionTypeID INT NOT NULL REFERENCES TransactionType(TransactionID),
    AssetID INT REFERENCES Asset(AssetID), -- Optional, as not all transactions may have assets
    Content TEXT,
    DateID INT NOT NULL REFERENCES Date(DateID),
    TimeID INT NOT NULL REFERENCES Time(TimeID),
    EntitySenderID INT NOT NULL REFERENCES Entities(EntityID), -- Entity sending the transaction
    EntityReceiverID INT NOT NULL REFERENCES Entities(EntityID), -- Entity receiving the transaction
    Amount DECIMAL(18, 2), -- Transaction amount, semi-additive as per description
    CONSTRAINT check_positive_amount CHECK (Amount >= 0)
);

-- Fact Table for Action 2: Incidents with Duration as the only measure

CREATE TABLE Incident (
    FactID SERIAL PRIMARY KEY,
    ServerID INT NOT NULL REFERENCES Server(ServerID),
    ServiceID INT NOT NULL REFERENCES Service(ServiceID),
    DateID INT NOT NULL REFERENCES Date(DateID),
    TimeID INT NOT NULL REFERENCES Time(TimeID),
    IncidentDuration INTERVAL, -- Additive measure for incident duration
    Description TEXT -- Optional description of the incident
);
