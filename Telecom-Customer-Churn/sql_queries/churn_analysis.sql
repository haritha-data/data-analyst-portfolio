CREATE DATABASE telecom_churn;
USE telecom_churn;

CREATE TABLE telecom_churn_80 (
    State VARCHAR(15),
    Account_length INT,
    Area_code INT,
    International_plan VARCHAR(3),
    Voice_mail_plan VARCHAR(3),
    Number_vmail_messages INT,
    Total_day_minutes DECIMAL(10,2),
    Total_day_calls INT,
    Total_day_charge DECIMAL(10,2),
    Total_eve_minutes DECIMAL(10,2),
    Total_eve_calls INT,
    Total_eve_charge DECIMAL(10,2),
    Total_night_minutes DECIMAL(10,2),
    Total_night_calls INT,
    Total_night_charge DECIMAL(10,2),
    Total_intl_minutes DECIMAL(10,2),
    Total_intl_calls INT,
    Total_intl_charge DECIMAL(10,2),
    Customer_service_calls INT,
    Churn tinyint(1)
);

CREATE TABLE telecom_churn_20 (
    State VARCHAR(15),
    Account_length INT,
    Area_code INT,
    International_plan VARCHAR(3),
    Voice_mail_plan VARCHAR(3),
    Number_vmail_messages INT,
    Total_day_minutes DECIMAL(10,2),
    Total_day_calls INT,
    Total_day_charge DECIMAL(10,2),
    Total_eve_minutes DECIMAL(10,2),
    Total_eve_calls INT,
    Total_eve_charge DECIMAL(10,2),
    Total_night_minutes DECIMAL(10,2),
    Total_night_calls INT,
    Total_night_charge DECIMAL(10,2),
    Total_intl_minutes DECIMAL(10,2),
    Total_intl_calls INT,
    Total_intl_charge DECIMAL(10,2),
    Customer_service_calls INT,
    Churn Tinyint(1)
);

select count(*) from telecom_churn_80;
select count(*) from telecom_churn_20;

-- Used Union all to merge both the files
CREATE TABLE telecom_churn_full AS
SELECT * FROM telecom_churn_80
UNION ALL
SELECT * FROM telecom_churn_20;

-- To check whether the count is still same after merging two files
SELECT COUNT(*) FROM telecom_churn_full;

SELECT Churn, COUNT(*) 
FROM telec
om_churn_full
GROUP BY Churn;

select * from telecom_churn_80;
select * from telecom_churn_20;
select * from telecom_churn_full;

-- total rows
select count(*) from telecom_churn_full;

-- chrun distribution
select churn, count(*) from telecom_churn_full
group by churn;

-- checking for null value
SELECT 
  SUM(CASE WHEN `Account_length` IS NULL THEN 1 ELSE 0 END) AS account_length_nulls,
  SUM(CASE WHEN `Total_day_minutes` IS NULL THEN 1 ELSE 0 END) AS day_minutes_nulls
FROM telecom_churn_full;

-- Adding new column tenure_bucket
Alter table telecom_churn_full add tenure_bucket Varchar(20);
UPDATE telecom_churn_full
SET tenure_bucket =
CASE
  WHEN account_length < 180 THEN '0–6 Months'
  WHEN account_length < 360 THEN '6–12 Months'
  WHEN account_length < 720 THEN '1–2 Years'
  ELSE '2+ Years'
END;

SET SQL_SAFE_UPDATES = 0;

-- validating tenure bucket
select tenure_bucket from telecom_churn_full;

-- High customer service calls flag
ALTER TABLE telecom_churn_full ADD high_service_calls_flag VARCHAR(10);
UPDATE telecom_churn_full
SET high_service_calls_flag =
CASE
  WHEN customer_service_calls >= 4 THEN 'High'
  ELSE 'Normal'
END;

-- Validating customer high service calls flag
select high_service_calls_flag from telecom_churn_full;

-- Total usage minutes
ALTER TABLE telecom_churn_full ADD total_usage_minutes DECIMAL(10,2);
UPDATE telecom_churn_full
SET total_usage_minutes =
total_day_minutes + total_eve_minutes + total_night_minutes + total_intl_minutes;

-- validating total usage minutes column
select total_usage_minutes from telecom_churn_full;

-- Total Customers
SELECT COUNT(*) AS total_customers
FROM telecom_churn_full;

-- Churned Customers
SELECT COUNT(*) AS churned_customers
FROM telecom_churn_full WHERE churn = 1;

-- Churn rate and Retention rate in %
SELECT ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate,
  ROUND(100.0 * (1 - SUM(churn) / COUNT(*)), 2) AS retention_rate
FROM telecom_churn_full;

-- Churn by contract behavior (Plans)
-- International plan vs churn
SELECT international_plan, COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY international_plan
ORDER BY churn_rate DESC;

-- Voice mail plan vs churn
SELECT voice_mail_plan, COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY voice_mail_plan
ORDER BY churn_rate DESC;

-- churn by tenure
SELECT tenure_bucket, COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY tenure_bucket
ORDER BY churn_rate DESC;

-- customer service calls impact
SELECT high_service_calls_flag, COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM telecom_churn_full
GROUP BY high_service_calls_flag;

-- Usage behavior vs churn
-- Average usage by churn
SELECT churn, ROUND(AVG(total_usage_minutes), 2) AS avg_usage_minutes
FROM telecom_churn_full
GROUP BY churn;

-- High vs low usage buckets
SELECT
CASE 
    WHEN total_usage_minutes >= 500 THEN 'High Usage'
    ELSE 'Low Usage'
  END AS usage_group,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY usage_group;

-- High risk customers
SELECT COUNT(*) AS high_risk_customers
FROM telecom_churn_full
WHERE
  high_service_calls_flag = 'High'
  AND tenure_bucket IN ('0–6 Months', '6–12 Months')
  AND voice_mail_plan = 'No';

-- Creating views to connect with power only with view not uploading full file
-- Customer view
CREATE VIEW view_churn_customers AS
SELECT
  State,
  account_length,
  tenure_bucket,
  international_plan,
  voice_mail_plan,
  customer_service_calls,
  high_service_calls_flag,
  total_usage_minutes,
  churn
FROM telecom_churn_full;

-- Churn KPI view
CREATE VIEW view_churn_kpis AS
SELECT
  COUNT(*) AS total_customers,
  SUM(churn) AS churned_customers,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate,
  ROUND(100.0 * (1 - SUM(churn) / COUNT(*)), 2) AS retention_rate
FROM telecom_churn_full;

-- Churn by tenure view
CREATE VIEW view_churn_by_tenure AS
SELECT tenure_bucket,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY tenure_bucket;

-- churn by plan view
CREATE VIEW view_churn_by_plan AS
SELECT international_plan, voice_mail_plan,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY international_plan, voice_mail_plan;

-- High risk customers view
CREATE VIEW view_high_risk_customers AS
SELECT *
FROM telecom_churn_full
WHERE
  high_service_calls_flag = 'High'
  AND tenure_bucket IN ('0–6 Months', '6–12 Months')
  AND voice_mail_plan = 'No';

-- Churn by usage view
CREATE OR REPLACE VIEW view_churn_by_usage AS
SELECT
  CASE 
    WHEN total_usage_minutes >= 500 THEN 'High Usage'
    ELSE 'Low Usage'
  END AS usage_group,
  COUNT(*) AS total_customers,
  SUM(Churn) AS churned_customers,
  ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM telecom_churn_full
GROUP BY usage_group;

select* from view_churn_by_usage;

-- churn by state view
CREATE OR REPLACE VIEW view_churn_by_state AS
SELECT State,
    COUNT(*) AS total_customers,
    SUM(Churn) AS churned_customers,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate
FROM telecom_churn_full
GROUP BY State;

select * from view_churn_by_state;
select * from telecom_churn_full;

-- churn by drivers summary
CREATE OR REPLACE VIEW vw_churn_drivers_summary AS
SELECT
    'High_Service_Calls' AS driver,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM telecom_churn_full
WHERE `Customer_service_calls` >= 4

UNION ALL

SELECT
    'No_Voice_Mail' AS driver,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)
FROM telecom_churn_full
WHERE Voice_mail_plan = 'No'

UNION ALL

SELECT
    'Short_Tenure' AS driver,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)
FROM telecom_churn_full
WHERE tenure_bucket = '0-6 Months';

SELECT * FROM vw_churn_drivers_summary;

-- View for churn by service calls
CREATE OR REPLACE VIEW vw_churn_by_service_calls AS
SELECT
    CASE
        WHEN `Customer_service_calls` >= 4 THEN 'High Service Calls'
        ELSE 'Low Service Calls'
    END AS high_service_call_flag,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM telecom_churn_full
GROUP BY high_service_call_flag;

Select * from vw_churn_by_service_calls;

-- View for drivers summary
CREATE OR REPLACE VIEW vw_churn_drivers_summary AS

SELECT
    'High Service Calls' AS driver,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2) AS churn_rate_pct
FROM telecom_churn_full
WHERE `Customer_service_calls` >= 4

UNION ALL

-- No Voice Mail
SELECT
    'No Voice Mail' AS driver,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)
FROM telecom_churn_full
WHERE `Voice_mail_plan` = 'No'

UNION ALL

-- Short Tenure
SELECT
    'Short Tenure' AS driver,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)
FROM telecom_churn_full
WHERE account_length < 180;




