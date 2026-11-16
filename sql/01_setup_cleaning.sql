-- Superstore Sales Analysis | 01_setup_cleaning.sql
-- Check data is safe to analyze

-- Check total rows
Select 
	Count(*) As Total_Rows
From [Sample - Superstore];

-- Check data types are correct
Select 
	COLUMN_NAME, DATA_TYPE
From INFORMATION_SCHEMA.COLUMNS
Where TABLE_NAME = 'Sample - Superstore';

-- Alter postal code type
Alter Table [Sample - Superstore]
Alter Column Postal_Code VARCHAR(20);

-- Check for duplicates
Select 
	Row_ID, 
	Count(*) As Total_Duplicates
From [Sample - Superstore]
Group by Row_ID
Having Count(*) > 1;

-- Check for rows that are the same in every column except Row_ID
Select
	Order_ID, 
	Product_ID, 
	Sales, 
	Quantity, 
	Discount, 
	Profit,
	Count(*) As Times_Seen
From [Sample - Superstore]
Group by 
	Order_ID, 
	Product_ID, 
	Sales, 
	Quantity, 
	Discount, 
	Profit
Having Count(*) > 1;

-- Check for missing values(NULL)
Select 
	Sum(Case When Order_ID IS NULL Then 1 Else 0 End) As Missing_Order_ID,
	Sum(Case When Order_Date IS NULL Then 1 Else 0 End) As Missing_Order_Date,
	Sum(Case When Customer_ID IS NULL Then 1 Else 0 End) As Missing_Customer_ID,
	Sum(Case When Sales IS NULL Then 1 Else 0 End) As Missing_Sales,
	Sum(Case When Profit IS NULL Then 1 Else 0 End) As Missing_Profit
From [Sample - Superstore];


-- Check for business logic & impossible values
Select
	Count(*) As Total_Invalids
From [Sample - Superstore]
Where Ship_Date < Order_Date
	OR Sales <= 0
	OR Quantity <= 0
	OR Discount < 0 
	OR Discount > 1;

-- Check postal codes are 5 digits long
Select
	Count(*) As Short_Postal_Codes
From [Sample - Superstore]
Where Len(Postal_Code) < 5;

-- Knowing the data
Select 
	Min(Order_Date) As First_Order,
	Max(Order_Date) As Last_Order,
	Count(Distinct Order_ID) As Total_Orders,
	Count(Distinct Customer_ID) As Total_Customers
From [Sample - Superstore];

-- Results (checked against the data):
-- 9,994 rows | no duplicate Row_ID | no missing values in the key columns | no invalid rows
-- One pair of rows is identical except for Row_ID (3406 and 3407). It was kept.
-- Orders from 2014-01-03 to 2017-12-30 | 5,009 orders | 793 customers
-- Known limit: 438 order lines have a postal code missing its leading zero in the source file.
-- Postal code is not used in the analysis.
