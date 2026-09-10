-- ============================================================
-- Telecom Customer Churn Analysis - MySQL Scripts
-- Database: customer_churn
-- Feeds: Power BI dashboard (Summary, Churn Reason, Churn Prediction pages)
--        and the Random Forest prediction notebook (see /ml)
-- ============================================================

USE customer_churn;

-- ============================================================
-- 1. EXPLORATORY QUERIES
-- ============================================================

-- Preview raw data
SELECT * FROM customer_data;

-- Churn/stay distribution by Gender
SELECT
    Gender,
    COUNT(Gender) AS TotalCount,
    (COUNT(Gender) / (SELECT COUNT(*) FROM customer_data)) * 100 AS Percentage
FROM customer_data
GROUP BY Gender;

-- Distribution by Contract type
SELECT
    Contract,
    COUNT(Contract) AS TotalCount,
    (COUNT(Contract) / (SELECT COUNT(*) FROM customer_data)) * 100 AS Percentage
FROM customer_data
GROUP BY Contract;

-- Distribution by Customer Status (Stayed/Churned/Joined)
SELECT
    Customer_Status,
    COUNT(Customer_Status) AS TotalCount,
    (COUNT(Customer_Status) / (SELECT COUNT(*) FROM customer_data)) * 100 AS Percentage
FROM customer_data
GROUP BY Customer_Status;

-- Distribution by State
SELECT
    State,
    COUNT(State) AS TotalCount,
    (COUNT(State) / (SELECT COUNT(*) FROM customer_data)) * 100 AS Percentage
FROM customer_data
GROUP BY State
ORDER BY Percentage DESC;

-- Distribution by Internet Type
SELECT
    Internet_Type,
    COUNT(*) AS Count
FROM customer_data
GROUP BY Internet_Type;


-- ============================================================
-- 2. DATA QUALITY CHECK - NULL / BLANK VALUES PER COLUMN
-- ============================================================

SELECT
    SUM(CASE WHEN Customer_ID IS NULL OR TRIM(Customer_ID) = '' THEN 1 ELSE 0 END) AS Customer_ID_Null_Count,
    SUM(CASE WHEN Gender IS NULL OR TRIM(Gender) = '' THEN 1 ELSE 0 END) AS Gender_Null_Count,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Age_Null_Count,
    SUM(CASE WHEN Married IS NULL OR TRIM(Married) = '' THEN 1 ELSE 0 END) AS Married_Null_Count,
    SUM(CASE WHEN State IS NULL OR TRIM(State) = '' THEN 1 ELSE 0 END) AS State_Null_Count,
    SUM(CASE WHEN Number_of_Referrals IS NULL THEN 1 ELSE 0 END) AS Number_of_Referrals_Null_Count,
    SUM(CASE WHEN Tenure_in_Months IS NULL THEN 1 ELSE 0 END) AS Tenure_in_Months_Null_Count,
    SUM(CASE WHEN Value_Deal IS NULL OR TRIM(Value_Deal) = '' THEN 1 ELSE 0 END) AS Value_Deal_Null_Count,
    SUM(CASE WHEN Phone_Service IS NULL OR TRIM(Phone_Service) = '' THEN 1 ELSE 0 END) AS Phone_Service_Null_Count,
    SUM(CASE WHEN Multiple_Lines IS NULL OR TRIM(Multiple_Lines) = '' THEN 1 ELSE 0 END) AS Multiple_Lines_Null_Count,
    SUM(CASE WHEN Internet_Service IS NULL OR TRIM(Internet_Service) = '' THEN 1 ELSE 0 END) AS Internet_Service_Null_Count,
    SUM(CASE WHEN Internet_Type IS NULL OR TRIM(Internet_Type) = '' THEN 1 ELSE 0 END) AS Internet_Type_Null_Count,
    SUM(CASE WHEN Online_Security IS NULL OR TRIM(Online_Security) = '' THEN 1 ELSE 0 END) AS Online_Security_Null_Count,
    SUM(CASE WHEN Online_Backup IS NULL OR TRIM(Online_Backup) = '' THEN 1 ELSE 0 END) AS Online_Backup_Null_Count,
    SUM(CASE WHEN Device_Protection_Plan IS NULL OR TRIM(Device_Protection_Plan) = '' THEN 1 ELSE 0 END) AS Device_Protection_Plan_Null_Count,
    SUM(CASE WHEN Premium_Support IS NULL OR TRIM(Premium_Support) = '' THEN 1 ELSE 0 END) AS Premium_Support_Null_Count,
    SUM(CASE WHEN Streaming_TV IS NULL OR TRIM(Streaming_TV) = '' THEN 1 ELSE 0 END) AS Streaming_TV_Null_Count,
    SUM(CASE WHEN Streaming_Movies IS NULL OR TRIM(Streaming_Movies) = '' THEN 1 ELSE 0 END) AS Streaming_Movies_Null_Count,
    SUM(CASE WHEN Streaming_Music IS NULL OR TRIM(Streaming_Music) = '' THEN 1 ELSE 0 END) AS Streaming_Music_Null_Count,
    SUM(CASE WHEN Unlimited_Data IS NULL OR TRIM(Unlimited_Data) = '' THEN 1 ELSE 0 END) AS Unlimited_Data_Null_Count,
    SUM(CASE WHEN Contract IS NULL OR TRIM(Contract) = '' THEN 1 ELSE 0 END) AS Contract_Null_Count,
    SUM(CASE WHEN Paperless_Billing IS NULL OR TRIM(Paperless_Billing) = '' THEN 1 ELSE 0 END) AS Paperless_Billing_Null_Count,
    SUM(CASE WHEN Payment_Method IS NULL OR TRIM(Payment_Method) = '' THEN 1 ELSE 0 END) AS Payment_Method_Null_Count,
    SUM(CASE WHEN Monthly_Charge IS NULL THEN 1 ELSE 0 END) AS Monthly_Charge_Null_Count,
    SUM(CASE WHEN Total_Charges IS NULL THEN 1 ELSE 0 END) AS Total_Charges_Null_Count,
    SUM(CASE WHEN Total_Refunds IS NULL THEN 1 ELSE 0 END) AS Total_Refunds_Null_Count,
    SUM(CASE WHEN Total_Extra_Data_Charges IS NULL THEN 1 ELSE 0 END) AS Total_Extra_Data_Charges_Null_Count,
    SUM(CASE WHEN Total_Long_Distance_Charges IS NULL THEN 1 ELSE 0 END) AS Total_Long_Distance_Charges_Null_Count,
    SUM(CASE WHEN Total_Revenue IS NULL THEN 1 ELSE 0 END) AS Total_Revenue_Null_Count,
    SUM(CASE WHEN Customer_Status IS NULL OR TRIM(Customer_Status) = '' THEN 1 ELSE 0 END) AS Customer_Status_Null_Count,
    SUM(CASE WHEN Churn_Category IS NULL OR TRIM(Churn_Category) = '' THEN 1 ELSE 0 END) AS Churn_Category_Null_Count,
    SUM(CASE WHEN Churn_Reason IS NULL OR TRIM(Churn_Reason) = '' THEN 1 ELSE 0 END) AS Churn_Reason_Null_Count
FROM customer_data;


-- ============================================================
-- 3. CLEANED PRODUCTION TABLE
-- ============================================================

CREATE TABLE prod_Churn AS
SELECT
    Customer_ID,
    Gender,
    Age,
    Married,
    State,
    Number_of_Referrals,
    Tenure_in_Months,
    CASE WHEN Value_Deal IS NULL OR TRIM(Value_Deal) = '' THEN 'None' ELSE Value_Deal END AS Value_Deal,
    Phone_Service,
    CASE WHEN Multiple_Lines IS NULL OR TRIM(Multiple_Lines) = '' THEN 'No' ELSE Multiple_Lines END AS Multiple_Lines,
    Internet_Service,
    CASE WHEN Internet_Type IS NULL OR TRIM(Internet_Type) = '' THEN 'None' ELSE Internet_Type END AS Internet_Type,
    CASE WHEN Online_Security IS NULL OR TRIM(Online_Security) = '' THEN 'No' ELSE Online_Security END AS Online_Security,
    CASE WHEN Online_Backup IS NULL OR TRIM(Online_Backup) = '' THEN 'No' ELSE Online_Backup END AS Online_Backup,
    CASE WHEN Device_Protection_Plan IS NULL OR TRIM(Device_Protection_Plan) = '' THEN 'No' ELSE Device_Protection_Plan END AS Device_Protection_Plan,
    CASE WHEN Premium_Support IS NULL OR TRIM(Premium_Support) = '' THEN 'No' ELSE Premium_Support END AS Premium_Support,
    CASE WHEN Streaming_TV IS NULL OR TRIM(Streaming_TV) = '' THEN 'No' ELSE Streaming_TV END AS Streaming_TV,
    CASE WHEN Streaming_Movies IS NULL OR TRIM(Streaming_Movies) = '' THEN 'No' ELSE Streaming_Movies END AS Streaming_Movies,
    CASE WHEN Streaming_Music IS NULL OR TRIM(Streaming_Music) = '' THEN 'No' ELSE Streaming_Music END AS Streaming_Music,
    CASE WHEN Unlimited_Data IS NULL OR TRIM(Unlimited_Data) = '' THEN 'No' ELSE Unlimited_Data END AS Unlimited_Data,
    Contract,
    Paperless_Billing,
    Payment_Method,
    Monthly_Charge,
    Total_Charges,
    Total_Refunds,
    Total_Extra_Data_Charges,
    Total_Long_Distance_Charges,
    Total_Revenue,
    Customer_Status,
    CASE WHEN Churn_Category IS NULL OR TRIM(Churn_Category) = '' THEN 'Others' ELSE Churn_Category END AS Churn_Category,
    CASE WHEN Churn_Reason IS NULL OR TRIM(Churn_Reason) = '' THEN 'Others' ELSE Churn_Reason END AS Churn_Reason
FROM customer_data;


-- ============================================================
-- 4. VIEWS FOR POWER BI
-- ============================================================

-- Churned + Stayed customers, used for churn analysis
CREATE VIEW vw_ChurnData AS
SELECT * FROM prod_Churn
WHERE Customer_Status IN ('Churned', 'Stayed');

-- Newly joined customers, used for new-joiner analysis
CREATE VIEW vw_JoinData AS
SELECT * FROM prod_Churn
WHERE Customer_Status = 'Joined';
