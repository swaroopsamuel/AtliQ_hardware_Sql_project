-- 01 Croma India product wise sales report for fiscal year 2021
SELECT 
*
FROM fact_sales_monthly
WHERE
customer_code=90002002 AND
get_fiscal_year(date)=2021 
ORDER BY date ASC;

-- 02 Finding Croma India product wise sales report for fiscal year 2021 and Q4
SELECT
*
FROM fact_sales_monthly
WHERE
customer_code=90002002 AND
get_fiscal_year(date)=2021 AND
get_fiscal_quarter(date)=”Q4”
ORDER BY date ASC;

-- 03 Croma India product wise sales report for Gross Monthly total sales
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


-- 04 Croma India product wise sales report for Yearly sales
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


		
