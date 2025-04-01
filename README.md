# SQL Project: Finance and Supply Chain Analytics

Welcome to the **Finance and Supply Chain Analytics** project! This project utilizes SQL queries and stored procedures to generate insightful reports and forecasts for **Croma India**, focusing on product sales, customer performance, and supply chain accuracy.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Database Schema](#database-schema)
- [Queries and Stored Procedures](#queries-and-stored-procedures)
- [Sales Reports](#sales-reports)
- [Top Customers, Products, Markets](#top-customers-products-markets)
- [Supply Chain Analytics](#supply-chain-analytics)

---

## 🚀 Project Overview

This project is focused on generating **finance and supply chain reports** for **Croma India** using SQL. The project helps analyze **sales data**, evaluate **forecasting accuracy**, and identify key trends in **customer** and **product performance**.

### Key Features:
- Product-wise **sales reports** for multiple fiscal years and quarters.
- Calculation of **gross sales**, **net sales**, and **deductions**.
- Insights into **top customers**, **products**, and **markets**.
- Evaluation of **supply chain forecasting errors** and accuracy.

---

## 🗂️ Database Schema

This project works with the following tables in the database:

| **Table Name**                     | **Description**                              |
|-------------------------------------|----------------------------------------------|
| `fact_sales_monthly`               | Monthly sales data for all products.        |
| `dim_product`                      | Product details including ID and name.      |
| `fact_gross_price`                 | Product pricing data.                       |
| `dim_customer`                     | Customer-related data.                      |
| `fact_pre_invoice_deductions`      | Pre-invoice deductions for products.        |
| `fact_post_invoice_deductions`     | Post-invoice deductions for products.       |
| `fact_act_est`                     | Forecasted vs. actual sales data.           |
| `dim_date`                         | Date-related data, including day, month, year, etc. |
| `fact_manufacturing_cost`          | Data related to manufacturing costs.        |
| `fact_forecast_monthly`            | Monthly sales forecast data.                |
| `fact_freight_cost`                | Data related to freight and shipping costs. |

---

## 📝 Queries and Stored Procedures

### Sales Reports

1. **Product-wise Sales Report for FY 2021**  
   Query for fetching sales data for Croma India for fiscal year 2021.
```sql
SELECT 
*
FROM fact_sales_monthly
WHERE
customer_code=90002002 AND
get_fiscal_year(date)=2021 
ORDER BY date ASC;
```
And I have created an user-defined function in order to retrieve the following fiscal_year
```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_year`(
calender_date DATE

) RETURNS int
DETERMINISTIC
BEGIN
DECLARE fiscal_year INT;
SET 	fiscal_year = YEAR(DATE_ADD(calender_date, INTERVAL 4 MONTH));
RETURN fiscal_year;
END
```
2. **Quarterly Sales Report for FY 2021**  
   Generates product-wise sales data for Q4 of 2021.

   Step:1 Have created an user-defined function in order to retrieve the following fiscal_year and Quarter.
```sql
CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_quarter`(

calender_date DATE

) RETURNS char(2) CHARSET utf8mb4
DETERMINISTIC
BEGIN
declare m TINYINT;
declare qtr char(2);
SET m = Month(calender_date);

CASE
WHEN m IN (9,10,11) THEN
SET qtr="Q1";
WHEN m IN (12,1,2) THEN
SET qtr="Q2";
WHEN m IN (3,4,5) THEN
SET qtr="Q3";
ELSE
SET qtr="Q4";
END CASE;
RETURN qtr;
END
```
Step:2 -Query for fetching product-wise sales data for Q4 of 2021.
```sql
SELCET 
*
FROM fact_sales_monthly
WHERE
customer_code=90002002 AND
get_fiscal_year(date)=2021 AND
get_fiscal_quarter(date)=”Q4”
ORDER BY date ASC;
```
3. **Monthly Gross Sales Report**  
   Retrieves monthly gross sales for all products in 2021.
```sql
SELECT
    s.date, 
    s.product_code, 
    p.product, 
    P.variant,
    s.sold_quantity,
    g.gross_price,
    ROUND(g.gross_price * s.sold_quantity,2) AS gross_price_total
FROM fact_sales_monthly AS s
JOIN dim_product AS p
    ON p.product_code = s.product_code
JOIN fact_gross_price AS g
    ON g.product_code = s.product_code 
    AND g.fiscal_year = get_fiscal_year(s.date)
WHERE s.customer_code = 90002002 AND
get_fiscal_year(s.date) =2021
ORDER BY s.date ASC;
```
4. **Yearly Gross Sales Report**  
   Displays total gross sales for the fiscal year.
```sql
SELECT
get_fiscal_year(date) as fiscal_year,
round(sum(g.gross_price*s.sold_quantity),2) AS gross_price_total
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON
g.product_code=s.product_code AND
g.fiscal_year=get_fiscal_year(date)
WHERE customer_code=90002002
GROUP BY fiscal_year
ORDER BY fiscal_year;
```
5. **Stored Procedure for Yearly Gross Sales**  
   A procedure to calculate yearly gross sales for selected customers.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_yearly_gross_sales`(
in_customer_codes INT
)
BEGIN
SELECT
get_fiscal_year(date) as fiscal_year,
ROUND(g.gross_price*s.sold_quantity,2) AS yearly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON  g.product_code = s.product_code AND
g.fiscal_year = get_fiscal_year(s.date)
WHERE
find_in_set(s.customer_code, in_customer_codes)>0
GROUP BY date;
END
```
6. **Stored Procedure for Monthly Gross Sales**  
   Retrieves monthly gross sales data based on customer input.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_for_customer`(
	in_customer_codes TEXT
)
BEGIN
SELECT
	s.date,
    ROUND(SUM(g.gross_price*s.sold_quantity),2) AS monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON 
	g.product_code = s.product_code AND
    g.fiscal_year = get_fiscal_year(s.date)
WHERE
	find_in_set(s.customer_code, in_customer_codes)>0
GROUP BY date;
END
```
7. **Stored Procedure for Market badge**  
   Query for market badge.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_market_badge`(
IN in_market varchar(45),
IN in_fiscal_year year,
OUT out_badge varchar(45)
)
BEGIN
DECLARE qty INT DEFAULT 0;

SET INDIA AS AN DEFAULT MARKET

IF in_market ="" THEN
SET in_market ="india";
END IF;

#RETRIEVE TOTAL QT FOR GIVEN MARKET+F(YEAR)

SELECT
c.market,
SUM(sold_quantity) AS total_qty
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE
get_fiscal_year(s.date) = in_fiscal_year AND
c.market =in_market
GROUP BY c.market;

#DETERMINE MARKET BADGE

IF qty > 5000000 THEN
SET out_badge ="Gold";
ELSE
SET out_badge = "Silver";
END IF;
END
```
---

### Top Customers, Products, Markets

1. **Net Sales Calculation with Deductions**  
   Queries to calculate net sales after considering both pre and post-invoice deductions.
   
   Step 1: Finding pre_invoice discount
```sql
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_pre_invoice_discount` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `c`.`customer_code` AS `customer_code`,
        `c`.`market` AS `market`,
        `s`.`product_code` AS `product_code`,
        `p`.`product` AS `product`,
        `p`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `g`.`gross_price` AS `gross_price_per_item`,
        ROUND((`g`.`gross_price` * `s`.`sold_quantity`),
                2) AS `gross_price_total`,
        `pre`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`
    FROM
        (((((`fact_sales_monthly` `s`
        JOIN `dim_product` `p` ON ((`p`.`product_code` = `s`.`product_code`)))
        JOIN `dim_date` `dt` ON ((`dt`.`calender_date` = `s`.`date`)))
        JOIN `fact_gross_price` `g` ON (((`g`.`product_code` = `s`.`product_code`)
            AND (`g`.`fiscal_year` = `s`.`fiscal_year`))))
        JOIN `dim_customer` `c` ON ((`c`.`customer_code` = `s`.`customer_code`)))
        JOIN `fact_pre_invoice_deductions` `pre` ON (((`pre`.`customer_code` = `s`.`customer_code`)
            AND (`pre`.`fiscal_year` = `s`.`fiscal_year`))))
```
Step 2: Finding post-invoice deduction + other deduction.
```sql
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_post_invoice_discount` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `s`.`product_code` AS `product_code`,
        `s`.`customer_code` AS `customer_code`,
        `s`.`market` AS `market`,
        `s`.`product` AS `product`,
        `s`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `s`.`gross_price_total` AS `gross_price_total`,
        `s`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        (`s`.`gross_price_total` - (`s`.`gross_price_total` * `s`.`pre_invoice_discount_pct`)) AS `net_invoice_sales`,
        (`po`.`discounts_pct` + `po`.`other_deductions_pct`) AS `post_invoice_discount_pct`
    FROM
        (`sales_pre_invoice_discount` `s`
        JOIN `fact_post_invoice_deductions` `po` ON (((`s`.`date` = `po`.`date`)
            AND (`s`.`product_code` = `po`.`product_code`)
            AND (`s`.`customer_code` = `po`.`customer_code`))))
```
Step 3: Finding net sales via views
```sql
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `net_sales` AS
    SELECT 
        `sales_post_invoice_discount`.`date` AS `date`,
        `sales_post_invoice_discount`.`fiscal_year` AS `fiscal_year`,
        `sales_post_invoice_discount`.`product_code` AS `product_code`,
        `sales_post_invoice_discount`.`customer_code` AS `customer_code`,
        `sales_post_invoice_discount`.`market` AS `market`,
        `sales_post_invoice_discount`.`product` AS `product`,
        `sales_post_invoice_discount`.`variant` AS `variant`,
        `sales_post_invoice_discount`.`sold_quantity` AS `sold_quantity`,
        `sales_post_invoice_discount`.`gross_price_total` AS `gross_price_total`,
        `sales_post_invoice_discount`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        `sales_post_invoice_discount`.`net_invoice_sales` AS `net_invoice_sales`,
        `sales_post_invoice_discount`.`post_invoice_discount_pct` AS `post_invoice_discount_pct`,
        (`sales_post_invoice_discount`.`net_invoice_sales` * (1 - `sales_post_invoice_discount`.`post_invoice_discount_pct`)) AS `net_sales`
    FROM
        `sales_post_invoice_discount`
```
2. **Top Markets by Net Sales**  
   Retrieves top 10 markets by net sales percentage for FY 2021.
```sql
SELECT
market,
sum(net_sales)
FROM net_sales
WHERE fiscal_year = 2021
GROUP BY market
```
3. **Top 3 Markets by Net Sales**  
   A stored procedure to list the top 3 markets based on net sales.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_n_market_by_net_sales`(
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN
SELECT 
	market,
    ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln
 FROM gdb0041.net_sales
WHERE fiscal_year = in_fiscal_year
GROUP BY market
ORDER BY net_sales_mln DESC
LIMIT in_top_n;
END
```
4. **Top 3 Customers by Net Sales**  
   A stored procedure to identify the top 3 customers by net sales.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_n_customer_by_net_sales`(
	in_market varchar(45),
    in_fiscal_year INT,
    in_top_n INT
)
BEGIN
	SELECT 
		customer,
		ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln
	 FROM gdb0041.net_sales n
	 JOIN dim_customer c
	 ON n.customer_code = c.customer_code
	WHERE fiscal_year = in_fiscal_year AND 
    n.market = in_market
	GROUP BY customer
	ORDER BY net_sales_mln DESC
	LIMIT in_top_n;
END
```
5. **Top 3 Products by Net Sales**  
   A procedure to find the top 3 products based on net sales.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_products_by_net_sales`(
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN
	SELECT 
		product,
		ROUND(SUM(net_sales)/1000000,2) AS net_sales_mln
	 FROM gdb0041.net_sales
	WHERE fiscal_year = in_fiscal_year
	GROUP BY product
	ORDER BY net_sales_mln DESC
	LIMIT in_top_n;
END
```
6. **Top N Products by Quantity Sold**  
   Query to retrieve the top N products based on total quantity sold.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_top_n_products_per_division_by_total_qty_sold`(
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN

WITH CTE1 AS (
		SELECT   
			p.division,    
			p.product,    
			SUM(sold_quantity) AS total_qty 
		FROM fact_sales_monthly s 
		JOIN dim_product p ON p.product_code = s.product_code 
		WHERE fiscal_year = in_fiscal_year 
		GROUP BY p.division, p.product),

	CTE2 AS(
	SELECT *,   
		DENSE_RANK() OVER(PARTITION BY division ORDER BY total_qty DESC) AS div_rank 
	FROM CTE1)

	SELECT *
	FROM CTE2
	WHERE div_rank <=  in_top_n;

END
```
7. **Top N Products by Region & Gross Sales**  
   A procedure to fetch the top N products for each region by gross sales.
```sql
CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_markets_in_region_by_gross_sales`(
	in_fiscal_year INT,
    in_top_n INT
)
BEGIN
WITH CTE1 AS(SELECT
	c.market,
    c.region,
    ROUND(SUM(gross_price_total)/1000000,2) AS gross_sales_mln
FROM gross_sales g
JOIN dim_customer c
	ON c.customer_code = g.customer_code
WHERE fiscal_year =in_fiscal_year
GROUP BY 1,2
ORDER BY gross_sales_mln DESC
),
CTE2 AS(	
SELECT	
    *,
    DENSE_RANK() OVER(PARTITION BY region ORDER BY gross_sales_mln DESC) AS drnk
FROM CTE1
)
SELECT
	*
FROM CTE2
WHERE drnk <=in_top_n;
END
```
---

### Supply Chain Analytics

1. **Forecasting Accuracy**  
   Queries to calculate forecast errors and accuracy by comparing forecasted vs. actual sales.
```sql
#(finding net_error, abs_error, pct for both) using temp table
CREATE TEMPORARY TABLE forecast_err_table
SELECT
s.customer_code,
SUM(forecast_quantity - sold_quantity) AS net_error,
ROUND(SUM(forecast_quantity - sold_quantity)* 100 / SUM(forecast_quantity),2) AS net_error_pct,
SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
ROUND(SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity),2) AS abs_error_pct
FROM fact_act_est s
WHERE fiscal_year = 2021
GROUP BY customer_code;

#finding forecast accuracy via derived column
SELECT
e.*,
c.customer,
c.market,
ROUND(IF(abs_error_pct>100,0,1-abs_error_pct),2) AS forecast_accuracy
FROM forecast_err_table e
JOIN dim_customer c USING (customer_code)
ORDER BY forecast_accuracy DESC;
```
2. **Forecast Accuracy Comparison (2021 vs 2020)**  
   Compares forecast accuracy between FY 2021 and FY 2020.
```sql

#Forecast_accuracy_2021 (finding net_error, abs_error, pct for both) using temp table
CREATE TEMPORARY TABLE forecast_accuracy_2021
WITH forecast_err_table_2021 AS(
SELECT
s.customer_code AS customer_code,
c.customer AS customer_name,
c.market AS market,
SUM(forecast_quantity - sold_quantity) AS net_error,
ROUND(SUM(forecast_quantity - sold_quantity)* 100 / SUM(forecast_quantity),2) AS net_error_pct,
SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
ROUND(SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity),2) AS abs_error_pct
FROM fact_act_est s
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE fiscal_year = 2021
GROUP BY customer_code
)

#Forecast_accuracy_2020 (finding net_error, abs_error, pct for both)
SELECT
*,
ROUND(IF(abs_error_pct>100,0,1-abs_error_pct),2) AS forecast_accuracy
FROM forecast_err_table_2021
ORDER BY forecast_accuracy DESC;

CREATE TEMPORARY TABLE forecast_accuracy_2020
WITH forecast_err_table_2020 AS(
SELECT
s.customer_code AS customer_code,
c.customer AS customer_name,
c.market AS market,
SUM(forecast_quantity - sold_quantity) AS net_error,
ROUND(SUM(forecast_quantity - sold_quantity)* 100 / SUM(forecast_quantity),2) AS net_error_pct,
SUM(ABS(forecast_quantity - sold_quantity)) AS abs_error,
ROUND(SUM(ABS(forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity),2) AS abs_error_pct
FROM fact_act_est s
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE fiscal_year = 2020
GROUP BY customer_code
)
#finding forecast accuracy via derived column
SELECT
*,
ROUND(IF(abs_error_pct>100,0,1-abs_error_pct),2) AS forecast_accuracy
FROM forecast_err_table_2020
ORDER BY forecast_accuracy DESC;

#joining both Forecast_accuracy_2021 & Forecast_accuracy_2020
SELECT
f_2020.customer_code,
f_2020.customer_name,
f_2020.market,
f_2020.forecast_accuracy AS forecast_acc_2020,
f_2021.forecast_accuracy AS forecast_acc_2021
FROM forecast_accuracy_2020 f_2020
JOIN forecast_accuracy_2021 f_2021
ON f_2020.customer_code = f_2021.customer_code
ORDER BY forecast_acc_2020 DESC;
```

## 🎯 Conclusion

This project provides a comprehensive SQL-based analysis of AtliQ sales, pricing, and financial performance. By leveraging advanced SQL queries and data manipulation techniques, we extracted meaningful insights to aid in strategic decision-making.  

Key takeaways include:  
✔️ Understanding sales trends and pricing strategies.  
✔️ Analyzing pre- and post-invoice deductions for revenue optimization.  
✔️ Comparing actual vs. forecasted performance for better planning.  
✔️ Evaluating manufacturing and freight costs to optimize profitability.  

🔗 **Let's connect on [LinkedIn](https://www.linkedin.com/in/swaroopnakka/) for more insights!**  
