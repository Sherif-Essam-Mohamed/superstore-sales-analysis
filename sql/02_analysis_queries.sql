-- Superstore Sales Analysis | 02_analysis_queries.sql
-- Table: [Sample - Superstore] (9,994 order lines) | Period: 2014-01-03 to 2017-12-30
-- Business question: where do strong sales fail to become profit?
-- Note: Sales is revenue after discount. Margin = Sum(Profit) / Sum(Sales).

-- Question: How big is the business, and how profitable is it overall?
-- Why it matters: this is the baseline every other result is compared with.
-- Finding: $2.30M in sales, $286k profit, a 12.47% margin, 5,009 orders, 793 customers.
Select 
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct,
	Count(Distinct Customer_ID) As Total_Customers,
	Count(Distinct Order_ID) As Total_Orders
From [Sample - Superstore];

-- Question: By what percentage did sales and profit grow each year?
-- Why it matters: shows whether growth is also making money.
-- Finding: sales fell 2.8% in 2015, then grew 29.5% (2016) and 20.4% (2017). Profit grew
-- 24.4%, 32.7% and 14.2%, so in 2017 sales grew faster than profit.
With Yearly As (
	Select 
		Year(Order_Date) As Order_Year,
		Sum(Sales) As Total_Sales, 
		Sum(Profit) As Total_Profit
	From [Sample - Superstore]
	Group by Year(Order_Date)
)
Select 
	Order_Year,
	Round(100.0 * (Total_Sales - Lag(Total_Sales) Over(Order by Order_Year))
		/ Lag(Total_Sales) Over(Order by Order_Year), 2) As Sales_Growth_pct,
	Round(100.0 * (Total_Profit - Lag(Total_Profit) Over(Order by Order_Year))
		/ Lag(Total_Profit) Over(Order by Order_Year), 2) As Profit_Growth_pct
From Yearly
Order by Order_Year;

-- Question: Which months peak, and does profit follow sales?
-- Why it matters: shows when to stock up and whether busy months are profitable.
-- Finding: November and December are 29.5% of all sales. The top sales month (Nov 2017,
-- about $118k) earned only about $9.7k profit, so profit does not follow sales.
Select
	Format(Order_Date, 'yyyy-MM') As Order_Month,
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct
From [Sample - Superstore]
Group by Format(Order_Date, 'yyyy-MM')
Order by Order_Month;

-- Question: Which category earns its share of sales?
-- Why it matters: shows which product groups carry the business and which don't.
-- Finding: Furniture is 32.3% of sales but only 6.4% of profit (2.5% margin).
-- Technology is 36.4% of sales and 50.8% of profit.
Select
Category,
Sum(Sales) As Total_Sales,
Sum(Profit) As Total_Profit,
Round(100.0 * Sum(Profit)
	/Sum(Sales), 2) As Profit_Margin_pct,
Round(100.0 * Sum(Sales) 
	/ (Select 
			Sum(Sales)
		From [Sample - Superstore]), 2) As Share_of_Sales_pct,
Round(100.0 * Sum(Profit)
	/ (Select 
			Sum(Profit)
		From [Sample - Superstore]), 2) As Share_of_Profit_pct 
From [Sample - Superstore]
Group by Category
Order by Total_Profit Desc;

-- Question: Which sub-categories sell a lot but earn little or lose money?
-- Why it matters: pinpoints where revenue is not turning into profit.
-- Finding: three sub-categories lose money: Tables (-$17.7k), Bookcases (-$3.5k) and
-- Supplies (-$1.2k). Tables rank 4th in sales but last in profit.
Select
	Sub_Category,
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit
From [Sample - Superstore]
Group by Sub_Category
Order by Total_Profit;

-- Question: Which products make the most profit?
-- Why it matters: shows which products to protect.
-- Finding: the Canon imageCLASS 2200 copier earns about $25.2k, more than the next
-- three products combined. Results rest on few order lines (3 to 10 each).
Select Top 5
	Product_Name,
	Count(*) AS Order_Lines,
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit
From [Sample - Superstore]
Group by Product_Name
Order by Total_Profit Desc;

-- Question: Which products lose the most money?
-- Why it matters: shows where to look first for pricing or cost problems.
-- Finding: the three worst are two Cubify 3D printers (-$8.9k and -$3.8k) and a Lexmark
-- laser printer (-$4.6k). Two conference tables also appear in the bottom five.
Select Top 5 
	Product_Name,
	Count(*) AS Order_Lines,
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit
From [Sample - Superstore]
Group by Product_Name
Order by Total_Profit;

-- Question: How do the four regions compare?
-- Why it matters: shows whether the problem is local or company-wide.
-- Finding: no region loses money overall, but Central earns only a 7.9% margin against
-- 14.9% in the West.
Select
	Region,
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct
From [Sample - Superstore]
Group by Region
Order by Total_Profit;

-- Question: Which states lose the most money?
-- Why it matters: shows where to focus pricing and discount reviews.
-- Finding: Texas (-$25.7k), Ohio (-$17.0k), Pennsylvania (-$15.6k) and Illinois (-$12.6k)
-- lose about $70.9k combined.
Select Top 10
	State,
	Sum(Sales) As Total_Sales, 
	Sum(Profit) As Total_Profit
From [Sample - Superstore]
Group by State
Order by Total_Profit;

-- Question: Where inside each region does profit turn negative?
-- Why it matters: shows whether a weak sub-category is weak everywhere or only in places.
-- Finding: 14 region and sub-category combinations lose money. The worst is Tables in
-- the East (about -$11.0k).
Select 
	Region,
	Sub_Category,
	Sum(Sales) As Total_Sales,
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct
From [Sample - Superstore]
Group by Region, Sub_Category
Having Sum(Profit) < 0
Order by Total_Profit;

-- Question: At what discount level do order lines stop being profitable?
-- Why it matters: finds the turning point for a discount policy.
-- Finding: margin is +29.5% with no discount and +11.8% at 20%, but -10.1% at 30%,
-- falling to -180% at 80%. Small groups (for example 11 lines at 45%) should not be over-read.
Select
	Discount,
	Count(*) As Order_Lines,
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct
From [Sample - Superstore]
Group by Discount
Order by Discount;

-- Question: How much profit is lost on heavily discounted lines?
-- Why it matters: puts a dollar value on the discount problem.
-- Finding: lines discounted 30% or more are 13.9% of lines and 15.8% of sales but lost
-- about $135k (-37.3% margin). All other lines earned about $422k (21.8% margin).
-- Note: this is an association, not proof that discounts cause the losses.
Select
    Case
        When Discount >= 0.3 Then '30%+ discount'
        Else 'Under 30% discount'
    End As Discount_Group,
    Count(*) AS Order_Lines,
	Sum(Sales) As Total_Sales,
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct,
    Round(100.0 * Count(*)
          / (Select
				Count(*)
			From [Sample - Superstore]), 2) As Share_of_Lines_pct,
    Round(100.0 * Sum(Sales)
          / (Select 
				Sum(Sales)
			From [Sample - Superstore]), 2) As Share_of_Sales_pct             
From [Sample - Superstore]
Group by
    Case
        When Discount >= 0.3 Then '30%+ discount'
        Else 'Under 30% discount'
    End
Order by Total_Profit;

-- Question: Does profit margin differ by shipping mode?
-- Why it matters: checks whether faster shipping hurts profitability.
-- Finding: margins are similar (12.1% to 13.9%). There is no evidence that faster shipping
-- lowers margin, but the data has no shipping cost, so this cannot be measured fully.
Select
	Ship_Mode,
	Round(Avg(Cast(DateDiff(day, Order_Date, Ship_Date) As Float)), 2) As Avg_Days_To_Ship,
	Sum(Sales) As Total_Sales,
	Sum(Profit) As Total_Profit,
	Round(100.0 * Sum(Profit)
		/Sum(Sales), 2) As Profit_Margin_pct
From [Sample - Superstore]
Group by Ship_Mode
Order by Profit_Margin_pct Desc;

-- Question: Are we dependent on a few customers? What share of profit comes from the top 10%?
-- Why it matters: heavy dependence on a few customers is a business risk.
-- Finding: the top 10% of customers (80 of 793) generate about 57.7% of total profit.
With Customer_Totals As (
    Select
        Customer_ID,
        Sum(Profit) AS Customer_Profit
    From [Sample - Superstore]
    Group by Customer_ID
),
Top_Customers As (
    Select Top 10 Percent
        Customer_ID,
        Customer_Profit
    From Customer_Totals
    Order by Customer_Profit Desc
)
Select
    Count(*) As Customers_In_Top_Group,
    Sum(Customer_Profit) As Top_10pct_Profit,
    Round(100.0 * Sum(Customer_Profit)
          / (Select 
				Sum(Profit)
			From [Sample - Superstore]), 2) As Share_of_Profit_pct
From Top_Customers;