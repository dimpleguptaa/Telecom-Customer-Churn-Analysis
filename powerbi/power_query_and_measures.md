# Power Query Transformations & DAX Measures

## Power Query Transformations

### Add columns to `prod_Churn`

```
Churn Status = if [Customer_Status] = "Churned" then 1 else 0
```
Data type changed to whole number.

```
Monthly Charge Range =
if [Monthly_Charge] < 20 then "< 20"
else if [Monthly_Charge] < 50 then "20-50"
else if [Monthly_Charge] < 100 then "50-100"
else "> 100"
```

### `mapping_AgeGrp` (reference table)

1. Keep only the `Age` column, remove duplicates.
2. Add `Age Group`:
```
if [Age] < 20 then "< 20"
else if [Age] < 36 then "20 - 35"
else if [Age] < 51 then "36 - 50"
else "> 50"
```
3. Add `AgeGrpSorting` (numeric, for correct visual ordering):
```
if [Age Group] = "< 20" then 1
else if [Age Group] = "20 - 35" then 2
else if [Age Group] = "36 - 50" then 3
else 4
```

### `mapping_TenureGrp` (reference table)

1. Keep only `Tenure_in_Months`, remove duplicates.
2. Add `Tenure Group`:
```
if [Tenure_in_Months] < 6 then "< 6 Months"
else if [Tenure_in_Months] < 12 then "6-12 Months"
else if [Tenure_in_Months] < 18 then "12-18 Months"
else if [Tenure_in_Months] < 24 then "18-24 Months"
else ">= 24 Months"
```
3. Add `TenureGrpSorting` (numeric, for correct visual ordering).

### `prod_Services` (reference table)

1. Unpivot all services columns.
2. Rename columns: `Attribute` → `Services`, `Value` → `Status`.

This reshapes the wide service flags (Online Security, Streaming TV, etc.) into a long Services/Status format, enabling a single flexible "churn rate by service" visual instead of one chart per service.

## DAX Measures

### Summary page

```
Total Customers = COUNT(prod_Churn[Customer_ID])

New Joiners =
CALCULATE(
    COUNT(prod_Churn[Customer_ID]),
    prod_Churn[Customer_Status] = "Joined"
)

Total Churn = SUM(prod_Churn[Churn Status])

Churn Rate = [Total Churn] / [Total Customers]
```

### Churn Prediction page

```
Count Predicted Churner = COUNT(Predictions[Customer_ID]) + 0

Title Predicted Churners =
"COUNT OF PREDICTED CHURNERS : " & COUNT(Predictions[Customer_ID])
```
