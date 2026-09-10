# Telecom Customer Churn Analysis (with ML Prediction)

An end-to-end churn analysis project on a telecom customer dataset: MySQL for data cleaning and transformation, Power BI for an interactive dashboard, and a Random Forest model in Python to predict which currently active customers are likely to churn next.

## Project Goals

1. Analyze customer data across key dimensions: demographic, geographic, account/payment, and services.
2. Study the churner profile and identify areas to target with retention or marketing campaigns.
3. Build a model to predict which of the newest customers are at risk of churning, so retention efforts can be targeted before they leave.

## Dataset

The source file is `Customer_Data.csv`, containing 6,400+ telecom customer records with fields covering:

- **Demographics**: Gender, Age, Married
- **Location**: State
- **Account info**: Tenure, Contract type, Payment Method, Paperless Billing, Charges, Refunds, Revenue
- **Services**: Phone, Internet (type), Online Security/Backup, Device Protection, Premium Support, Streaming TV/Movies/Music, Unlimited Data
- **Status**: Customer Status (Stayed/Churned/Joined), Churn Category, Churn Reason

## Tech Stack

- **MySQL** — data cleaning, transformation, and ETL
- **Power BI** — interactive dashboard and reporting
- **Python (pandas, scikit-learn, Jupyter Notebook)** — churn prediction model (Random Forest)

## My Approach & Thought Process

I've broken this down by the decision points in the project, and why I made each call, since the "how" mattered as much as the output.

**1. Why I started with the database layer instead of going straight to Power BI**

I could have loaded the raw CSV directly into Power BI and cleaned it there with Power Query. I chose not to, because the raw file had inconsistent nulls and blanks scattered across almost every service column (Online Security, Streaming TV, Value Deal, etc.), and I wanted a single, reusable "clean" source of truth rather than re-running Power Query transformations every time I refreshed data. Doing the cleaning once in the database, then exposing it through views, keeps the Power BI file lighter and the logic auditable in SQL rather than buried in M code.

**2. Why MySQL instead of the SQL Server / SSIS setup from the reference tutorial**

The tutorial I followed used SQL Server Management Studio and SSIS for the import step. I used MySQL instead, mainly because it's free, lightweight, and something I already had set up, and SSIS specifically is a SQL Server-only tool, it wouldn't have transferred over anyway. The actual cleaning logic (null handling, categorical defaults, view creation) doesn't depend on which RDBMS you use, so switching engines didn't change the core approach, only the import method (I used MySQL Workbench's import wizard instead of SSIS) and small syntax differences.

**3. Why I checked every column for nulls before deciding how to fill them**

Rather than blanket-filling every null the same way, I ran a column-by-column null count first. This mattered because different columns needed different logic: a blank in `Value_Deal` genuinely means "customer isn't on a deal" (so `'None'` is correct), while a blank in `Online_Security` means "doesn't have the service" (so `'No'` is correct), those aren't interchangeable, and filling them wrong would have quietly distorted every downstream churn-by-service metric.

**4. Why I split the cleaned data into two views instead of one**

`vw_ChurnData` (Stayed + Churned) and `vw_JoinData` (Joined) serve two different analytical purposes. Churn analysis needs a clear binary outcome to measure against, new joiners haven't had time to churn yet, so mixing them in with churn-rate calculations would understate the true rate. Separating them at the view level meant I didn't have to filter for this every time in DAX or Python, it's handled once, upstream.

**5. Why I built the prediction model as a separate step, using the same cleaned views**

Once the dashboard was in place, the natural next question was "who's likely to churn next?" I trained the Random Forest model on `vw_ChurnData` (customers with a known Stayed/Churned outcome), since that's the only data with a real label to learn from, then applied the trained model to `vw_JoinData` (customers with no history yet) to generate predictions. Reusing the same cleaned views for both the dashboard and the model kept the two consistent, if I'd cleaned the data differently for the ML step, I might get plausible-looking but non-comparable numbers between the dashboard and the predictions.

**6. Why Random Forest specifically**

I chose Random Forest over a single decision tree because it reduces overfitting by averaging across many trees trained on random subsets of the data and features, this matters here because the dataset has many correlated service/account columns (e.g. Contract type is very likely correlated with Tenure and Monthly Charge), and a single tree would risk keying too heavily on one dominant feature.

**7. Why I looked at precision and recall separately, not just accuracy**

85% accuracy on its own would have sounded fine but hidden the real story. Since only about 30% of the test set actually churned, a model that just predicted "stayed" most of the time could still score high on accuracy. I looked at recall for the churn class specifically (65%) because in a retention use case, missing an actual churner (a false negative) is more costly than flagging a customer who ends up staying (a false positive), so recall on the "Churned" class is the more business-relevant number here, even though it's the metric where the model is weakest. That's a real limitation I'd flag rather than gloss over (see Limitations below).

## ETL & Data Cleaning (MySQL)

1. Loaded the raw CSV into a `customer_data` table in a `customer_churn` database.
2. Ran exploratory queries to check distribution across Gender, Contract, Customer Status, State, and Internet Type.
3. Checked every column for null/blank values using conditional aggregation.
4. Built a cleaned table, `prod_Churn`, replacing nulls/blanks in categorical service columns with sensible defaults (`'No'` for service flags, `'None'` for value deal/internet type, `'Others'` for churn category/reason).
5. Created two views for reporting and modeling: `vw_ChurnData` (Churned + Stayed) and `vw_JoinData` (Joined).

## Power Query Transformations & DAX Measures (Power BI)

- Added a numeric `Churn Status` flag (1 = Churned, 0 = otherwise) to `prod_Churn` for aggregation.
- Added a `Monthly Charge Range` bucket (`< 20`, `20-50`, `50-100`, `> 100`).
- Built two mapping tables, `mapping_AgeGrp` and `mapping_TenureGrp`, with sort-order columns so age and tenure groups display in logical order rather than alphabetically.
- Unpivoted the services columns into a `prod_Services` table (Services / Status) to support a single flexible "churn rate by service" visual instead of one chart per service.
- Key measures: `Total Customers`, `New Joiners`, `Total Churn`, `Churn Rate`, plus `Count Predicted Churner` and a dynamic title measure for the prediction page.

## Machine Learning: Churn Prediction (Random Forest)

- **Tooling**: Python 3, Jupyter Notebook, pandas, scikit-learn.
- **Training data**: `vw_ChurnData` (customers with a known Stayed/Churned outcome).
- **Preprocessing**: dropped identifier/leakage columns (`Customer_ID`, `Churn_Category`, `Churn_Reason`), label-encoded categorical fields, mapped the target (`Stayed`→0, `Churned`→1), 80/20 train-test split.
- **Model**: `RandomForestClassifier(n_estimators=100, random_state=42)`.
- **Scoring data**: `vw_JoinData` (customers with no churn history yet, i.e. newest joiners), same encoders applied, predictions filtered to those classified as likely to churn.
- **Output**: `Predictions.csv`, fed back into Power BI as a third dashboard page.

### Model Performance

| Metric | Value |
|---|---|
| Accuracy | 85% |
| Precision (Churned class) | 83% |
| Recall (Churned class) | 65% |
| F1-score (Churned class) | 73% |
| Test set size | 1,202 customers |

### Limitations

Recall on the churn class (65%) means the model misses roughly a third of actual churners in testing, it's a reasonable first-pass model, not a production-grade one. Improving this further would likely mean trying class-balancing techniques (e.g. SMOTE, class weighting) or comparing against gradient-boosted models, both flagged as future work below.

## Power BI Dashboard

The dashboard (`customer_churn_powerbi.pbix`) connects to the MySQL views and has two pages:

**Summary**
- KPI cards: Total Customers, New Joiners, Total Churn, Churn Rate
- Churn by Gender and by Age Group (Demographic)
- Churn rate by State (Geographic)
- Churn rate by Internet Type and by individual Services (Services Used)
- Churn rate by Payment Method and by Contract (Account Info)
- Total Customers and Churn rate by Tenure Group

**Churn Prediction**
- Predicted Churner Profile: gender split, breakdowns by state, age group, marital status, tenure group, payment method, and contract
- Customers at Risk table (Customer_ID, Monthly Charge, Total Revenue, Total Refunds, Number of Referrals)
- 381 customers from the newest joiners flagged as likely to churn

### Key Metrics (current snapshot)

| Metric | Value |
|---|---|
| Total Customers | 6,418 |
| New Joiners | 411 |
| Total Churn | 1,732 |
| Churn Rate | 26.99% |
| Predicted At-Risk Customers (from newest joiners) | 381 |

## Impact Matrix — Churn Rate by Segment

| Segment | Churn Rate | vs. Baseline (26.99%) |
|---|---|---|
| Two-Year Contract | 2.7% | −90.0% |
| One-Year Contract | 11.0% | −59.2% |
| Month-to-Month Contract | 46.5% | +72.3% |
| With Online Security | 14.6% | −45.9% |
| Without Online Security | 42.4% | +57.1% |
| DSL Internet | 19.4% | −28.1% |
| Cable Internet | 25.7% | −4.8% |
| Fiber Optic Internet | 41.1% | +52.3% |

*Percentage change is relative to the overall baseline churn rate of 26.99%. E.g. month-to-month customers churn at a rate 72.3% higher than the overall average, while two-year contract customers churn at a rate 90% lower.*

## Key Insights

- Month-to-month contracts show a substantially higher churn rate than one-year or two-year contracts, this is the single strongest lever in the dataset.
- Fiber optic internet customers churn at a noticeably higher rate than DSL or cable users.
- Customers without add-on services (Online Security, Device Protection, Premium Support) churn more than those with them.
- Churn is concentrated in the earliest tenure brackets, tapering off for longer-tenured customers.
- Competitor-related reasons and dissatisfaction are the leading churn categories.
- Churned customers had an 18.2% higher average monthly charge than customers who stayed, suggesting price sensitivity plays a role alongside contract and service factors.

## Business Impact

- **Revenue at risk**: Churned customers accounted for ~$3.41M in lifetime revenue, and represent roughly $1.52M in lost annualized recurring revenue (monthly charges × 12) if they aren't recovered or replaced.
- **Contract type is the single biggest lever**: moving month-to-month customers onto annual contracts could cut their churn risk by more than half, based on the one-year contract's 59% lower churn rate relative to baseline.
- **Add-on services reduce churn**: bundling Online Security or similar add-ons at signup is a comparatively low-cost retention lever, given the 46% lower churn rate among customers who have it.
- **Fiber optic customers are highest-risk**: worth investigating with the product/network team whether this is a service-quality or pricing issue.
- **Actionable output**: the 381 at-risk customers identified by the model give the retention team a concrete, prioritized list to act on now, rather than waiting for these customers to churn before responding.

*Note: figures are computed directly from the dataset and are illustrative of the kind of business case this analysis supports, not audited financial projections.*

## Repository Structure

```
├── Customer_Data.csv                 # Source dataset
├── sql/
│   └── churn_analysis.sql            # ETL, cleaning, views
├── power_query_and_measures.md       # Power Query steps & DAX measures
├── ml/
│   ├── churn_prediction.ipynb        # Random Forest training & scoring
│   ├── prediction_data.xlsx          # Input data (vw_ChurnData / vw_JoinData) for the notebook
│   └── Predictions.csv               # Model output — predicted at-risk customers
├── customer_churn_powerbi.pbix       # Power BI dashboard file 
└── README.md
```

## Next Steps

- Improve recall on the churn class via class-balancing (SMOTE / class weights) or by comparing against gradient-boosted models (XGBoost/LightGBM).
- Automate the prediction refresh so new joiners are scored on a schedule rather than manually.
- Add a drill-through from the Churn Prediction page to individual customer profiles for the retention team.

