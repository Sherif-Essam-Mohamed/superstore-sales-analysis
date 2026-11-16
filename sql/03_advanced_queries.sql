-- Superstore Sales Analysis | 03_advanced_queries.sql
-- CTEs, window functions and follow-up checks.

-- Question: How did cumulative profit build up month by month?
-- Why it matters: shows whether profit was earned steadily or in bursts.
-- Finding: cumulative profit reached about $49.5k by Dec 2014, $111.2k by Dec 2015, $193.0k
-- by Dec 2016 and $286.4k by Dec 2017. Only 2 of 48 months lost money (Jul 2014, -$841;
-- Jan 2015, -$3,281), so profit built up steadily.
With Monthly As(
	Select
		Format(Order_Date, 'yyyy-MM') As Order_Month,
		Sum(Profit) As Monthly_Profit
	From [Sample - Superstore]
	Group by Format(Order_Date, 'yyyy-MM') 
)
Select
	Order_Month,
	Monthly_Profit,
	Round(Sum(Monthly_Profit) Over(
        Order by Order_Month 
        Rows Between Unbounded Preceding And Current Row
        ), 2) As Running_Profit
From Monthly
Order by Order_Month;

-- Question: Which sub-categories rank high in sales but low in profit?
-- Why it matters: a sub-category can be a top seller and still lose money.
-- Ranking sales and profit side by side shows exactly where revenue is not becoming profit.
-- Finding: Tables rank 4th in sales but 17th (last) in profit, a gap of 13. Machines (6th vs 13th)
-- and Bookcases (9th vs 16th) show the same pattern. Copiers and Paper are the opposite:
-- 8th and 12th in sales, but 1st and 4th in profit.
With Sub As(
	Select
		Sub_Category,
		Sum(Profit) As Total_Profit,
		Sum(Sales) As Total_Sales
	From [Sample - Superstore]
	Group by Sub_Category
)
Select
	Sub_Category,
	Total_Profit,
	Total_Sales,
	Rank() Over(Order by Total_Profit Desc) As Profit_Rank,
	Rank() Over(Order by Total_Sales Desc) As Sales_Rank,
	Rank() Over(Order by Total_Profit Desc)
		- Rank() Over(Order by Total_Sales Desc) As Rank_Gap
From Sub
Order by Rank_Gap Desc;

-- Question: Do Tables and Bookcases lose money at every discount level, or only at heavy discounts?
-- Why it matters: comparing the same product type removes the "maybe it's just a bad product"
-- explanation. If losses appear only at heavy discounts, discounting is the likelier driver.
-- Finding: both sub-categories are profitable under a 30% discount (Tables +$13.0k, 11.1% margin;
-- Bookcases +$7.6k, 8.8%) but lose heavily at 30%+ (Tables -$30.7k, -34.1%; Bookcases -$11.1k,
-- -38.9%). This is consistent with discounting driving the losses, not proof of it.
Select
	Sub_Category,
	Case 
		When Discount >= 0.3 Then '30%+ Discount'
		Else 'Under 30% Discount'
	End As Discount_Group,
	Count(*) As Order_Line,
	Sum(Profit) As Total_Profit,
	Sum(Sales) As Total_Sales,
	Round(100.0 * Sum(Profit)
		/ Sum(Sales), 2) As Margin_pct
From [Sample - Superstore]
Where Sub_Category In('Tables', 'Bookcases')
Group by 
	Sub_Category,
	Case
		When Discount >= 0.3 Then '30%+ Discount'
		Else 'Under 30% Discount'
	End
Order by 
	Sub_Category,
	Discount_Group;

-- Question: Why does Supplies lose money when it has no heavy discounts?
-- Why it matters: Tables and Bookcases are explained by heavy discounts. Supplies is not, so it needs its own check.
-- Finding: Supplies earns +$1,718 at 0% discount (117 lines) but loses -$2,907 at 20% (73 lines).
-- Saved as: reports/tables/21_supplies_by_discount.csv
Select
	Discount,
	Count(*) As Order_Lines,
	Sum(Profit) As Total_Profit
From [Sample - Superstore]
Where Sub_Category = 'Supplies'
Group by Discount
Order by Discount;

-- Question: Which Supplies products lose the most money?
-- Why it matters: Supplies loses money without heavy discounts, so we check whether a few products cause the loss.
-- Finding: The three biggest losers are letter openers (Martin Yale Chadless Opener -$1,299, Premier Automatic -$428, 
-- High Speed Automatic Electric -$262). The Martin Yale model alone is more than the rest.
-- Saved as: reports/tables/22_supplies_by_product.csv
Select
	Product_Name,
	Count(*) As Order_Lines,
	Sum(Profit) As Total_Profit
From [Sample - Superstore]
Where Sub_Category = 'Supplies'
Group by Product_Name
Order by Total_Profit;

-- Question: Is the Supplies loss at 20% discount caused by letter openers?
-- Why it matters: shows whether the problem is the whole sub-category or one product type.
-- Finding: letter openers earn a 3% margin at full price and lose $2,996 at a 20% discount (-21%).
-- Other Supplies products stay profitable at 20% (+$89, 8% margin).
-- Saved as: reports/tables/23_supplies_letter_openers.csv
Select
	Discount,
	Case
		When Product_Name Like '%Opener%' Then 'Letter openers'
		Else 'Other Supplies'
	End As Product_Group,
	Count(*) As Order_Lines,
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/ Sum(Sales), 2) As Profit_Margin_pct
From [Sample - Superstore]
Where Sub_Category = 'Supplies'
Group by
	Discount,
	Case
		When Product_Name Like '%Opener%' Then 'Letter openers'
		Else 'Other Supplies'
	End
Order by
	Discount,
	Product_Group;

-- Question: Which three products earn the most profit in each region?
-- Why it matters: shows whether each region depends on the same few products or different ones,
-- which affects stock planning and risk.
-- Finding: the Canon imageCLASS 2200 Advanced Copier is the top profit earner in Central ($8.4k),
-- East ($10.1k) and West ($6.7k). The South differs: its top product is the Fellowes PB500
-- binding machine ($3.8k). Of the 12 products, 9 are Technology (copiers and machines) and
-- 3 are binding machines from Office Supplies.
With Products_Total As(
	Select
		Product_Name,
		Region,
		Sum(Profit) As Total_Profit,
		Sum(Sales) As Total_Sales
	From [Sample - Superstore]
	Group by 
		Product_Name,
		Region 
),
Ranked As(
	Select
		Product_Name,
		Region,
		Total_Profit,
		Total_Sales,
		Row_Number() Over(Partition by Region Order by Total_Profit Desc) As Rank_In_Region
	From Products_Total
)
Select
	Product_Name,
	Region,
	Total_Profit,
	Total_Sales,
	Rank_In_Region
From Ranked
Where Rank_In_Region <= 3
Order by 
	Region,
	Rank_In_Region;

-- Question: How concentrated is profit across customers?
-- Why it matters: heavy dependence on a few customers is a business risk, and losing customers
-- at the bottom may actually help profit.
-- Finding: the top 10% of customers (80 of 793) earn 57.7% of total profit and the top 20% earn
-- about 82%. The bottom two groups lose about $71k combined.
With Customer_Totals As (
    Select
        Customer_ID,
        Sum(Profit) AS Customer_Profit
    From [Sample - Superstore]
    Group by Customer_ID
),
Deciles As(
	Select
		Customer_ID,
		Customer_Profit,
		Ntile(10) Over(Order by Customer_Profit Desc) As Decile
	From Customer_Totals
)
Select
	Decile,
	Count(*) As Total_Customers,
	Sum(Customer_Profit) As Group_Profit,
	Round(100.0 * Sum(Customer_Profit)
		/ (Select
				Sum(Profit)
			From [Sample - Superstore]), 2) As Share_of_Profit_pct
From Deciles
Group by Decile
Order by Decile;

-- Question: Is the business really growing once seasonal spikes are smoothed out?
-- Why it matters: sales jump every November and December, so comparing one month to the next
-- is misleading. Smoothing and same-month comparisons show the true direction.
-- Finding: comparing the same period each year, the 3-month average of sales ending in December rose from
-- about $59.9k (2014) to $60.8k (2015), $78.7k (2016) and $93.4k (2017), so sales grew every year.
-- A single month can mislead: December 2017 is 13.6% below December 2016, but November 2017 was 49.2% above November 2016.
With Monthly As(
	Select
		Format(Order_Date, 'yyyy-MM') As Order_Month,
		Sum(Profit) As Monthly_Profit,
		Sum(Sales) As Monthly_Sales
	From [Sample - Superstore]
	Group by Format(Order_Date, 'yyyy-MM')
)
Select
	Order_Month,
	Monthly_Sales,
	Round(Avg(Monthly_Sales) Over(Order by Order_Month
	Rows Between 2 Preceding And Current Row), 2) As Moving_Avg_3M,
	Round(100.0 * (Monthly_Sales - Lag(Monthly_Sales, 12) Over(Order by Order_Month))
		/ Lag(Monthly_Sales, 12) Over(Order by Order_Month), 2) As Same_Month_Growth_pct
From Monthly
Order by Order_Month;


