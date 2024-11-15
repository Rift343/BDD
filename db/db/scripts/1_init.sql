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
    Country VARCHAR(100),
    YearOfJoiningSWIFT INT CHECK (YearOfJoiningSWIFT BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    LegalJurisdiction VARCHAR(100),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(20),
    FraudPreventionContact VARCHAR(100),
    BeneficialOwner VARCHAR(100),
    Language VARCHAR(100),
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
    TransactionName VARCHAR(100),
    TransactionType VARCHAR(100),
    Description TEXT,
    Category VARCHAR(100),
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
    AssetName VARCHAR(100),
    UnitDivisibility DECIMAL(18, 8), -- Support for divisibility in financial assets
    CountryOfOrigin VARCHAR(100),
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
    Cluster VARCHAR(100),
    OperatingSystem VARCHAR(100),
    CPUCores INT CHECK (CPUCores > 0),
    MemoryCapacity INT CHECK (MemoryCapacity > 0), -- in GB
    ECCMemory BOOLEAN,
    StorageCapacity INT CHECK (StorageCapacity > 0), -- in GB
    NetworkBandwidth INT CHECK (NetworkBandwidth > 0), -- in Mbps
    Manufacturer VARCHAR(100),
    ServerRole VARCHAR(100),
    Environment VARCHAR(20) CHECK (Environment IN ('Production', 'Test', 'Development'))
);

-- Dimension: Service
CREATE TABLE Service (
    ServiceID SERIAL PRIMARY KEY,
    ServiceName VARCHAR(100),
    ServiceType VARCHAR(100),
    CriticalityLevel VARCHAR(10) CHECK (CriticalityLevel IN ('High', 'Medium', 'Low')),
    Description TEXT,
    IsRedundant BOOLEAN,
    Vendor VARCHAR(100),
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
    Description TEXT, -- Optional description of the incident
	SEVERITY INT
);

CREATE MATERIALIZED VIEW TWENTYTHREEANDTWO AS 
SELECT D.FiscalYear, D.Quarter 
FROM Messages M, Date D, Entities E 
WHERE E.country IN ('Germany', 'France', 'Spain', 'Italy', 'Netherlands',
    'Belgium', 'Austria', 'Poland', 'Sweden', 'Greece',
    'Portugal', 'Denmark', 'Ireland', 'Finland', 'Cyprus',
    'Estonia', 'Hungary', 'Latvia', 'Lithuania', 'Luxembourg',
    'Malta', 'Romania', 'Slovakia', 'Slovenia', 'Bulgaria',
    'Croatia', 'Czech Republic') 
    AND (D.FiscalYear BETWEEN 2022 AND 2023) AND
    M.DateID = D.DateID AND M.EntitySenderID = E.EntityID
    ;

CREATE VIEW MESSAGE_CHINA AS 
	SELECT M.FactID,D.Month,D.Year 
	FROM Messages M, Date D, Entities E 
	WHERE E.Country = 'China' AND M.DateID = D.DateID AND (M.EntityReceiverID=E.EntityID OR M.EntitySenderID=E.EntityID);

CREATE VIEW JOIN_ENTITY_MESSAGE AS
	SELECT M.FactID,E.Country,D.Month,D.Year,D.Quarter,E.EntityName
	FROM MESSAGES M, Entities E,Date D
	WHERE (M.EntitySenderID = E.EntityID OR M.EntityReceiverID = E.EntityID) AND M.DateID = D.DateID;

CREATE VIEW JOIN_MESSAGE_ASSET AS
	SELECT M.FactID,A.AssetID,A.AssetName
	FROM Messages M, Asset A
	WHERE M.AssetID = A.AssetID;

CREATE VIEW JOIN_MESSAGE_TYPE_WITH_DATE AS
	SELECT D.FiscalYear, D.Quarter, T.TransactionType
	FROM Messages M, Date D, TransactionType T 
	WHERE M.TransactionTypeID = T.TransactionID AND M.DateID=D.DateID;

CREATE OR REPLACE FUNCTION NB_ASSET(PARAM1 INTEGER)
RETURNS INTEGER AS $$
DECLARE NB INTEGER;
BEGIN
    SELECT COUNT(*) INTO NB FROM JOIN_MESSAGE_ASSET j WHERE j.AssetID = PARAM1;
    RETURN NB;
END;
$$ LANGUAGE plpgsql;

CREATE MATERIALIZED VIEW groupByServiceAndFact AS 
SELECT S.ServiceName,COUNT(*) 
FROM Incident I, Service S 
GROUP BY(ServiceName);

CREATE MATERIALIZED VIEW Incident_groupBy_Sev AS
SELECT SEVERITY,AVG(IncidentDuration)
FROM  Incident GROUP BY (Severity) ;

CREATE MATERIALIZED VIEW TOTAL_DUREE_INCIDENT_SERVICE AS 
SELECT S.ServiceName, SUM(I.IncidentDuration) AS totalDuration  
FROM Incident I 
JOIN Service S ON I.ServiceID = S.ServiceID 
GROUP BY(S.ServiceName);


SELECT Month, Year, COUNT(*) messages_chine FROM MESSAGE_CHINA GROUP BY (Month,Year);

SELECT* FROM Incident_groupBy_Sev;

SELECT * FROM groupByServiceAndFact;

SELECT AssetID,AssetName,NB_ASSET(AssetID) FROM JOIN_MESSAGE_ASSET GROUP BY(AssetID,AssetName);

SELECT JOIN_MESSAGE_TYPE_WITH_DATE.FiscalYear, JOIN_MESSAGE_TYPE_WITH_DATE.Quarter, JOIN_MESSAGE_TYPE_WITH_DATE.TransactionType, COUNT(*) 
FROM JOIN_MESSAGE_TYPE_WITH_DATE 
GROUP BY(JOIN_MESSAGE_TYPE_WITH_DATE.FiscalYear, JOIN_MESSAGE_TYPE_WITH_DATE.Quarter, JOIN_MESSAGE_TYPE_WITH_DATE.TransactionType);

SELECT Year, Month , COUNT(*) messages_BCE 
FROM JOIN_ENTITY_MESSAGE   
WHERE EntityName = 'European Central Bank' GROUP BY (Year, Month);

SELECT Country, COUNT(*) AS transactions_messages 
FROM JOIN_ENTITY_MESSAGE 
GROUP BY(Country);

SELECT D.FiscalYear, D.Quarter, COUNT(*) as NBMESSAGE 
FROM Messages M, Date D WHERE  (D.FiscalYear BETWEEN 2021 AND 2023) AND D.DateID = M.DateID
GROUP BY(D.FiscalYear,D.Quarter);

SELECT SUM(totalDuration) / 60  FROM TOTAL_DUREE_INCIDENT_SERVICE WHERE ServiceName = 'Swift Network';