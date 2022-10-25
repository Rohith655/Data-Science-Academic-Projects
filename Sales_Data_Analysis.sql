CREATE DATABASE PortfolioProjects;
USE PortfolioProjects;
SELECT * FROM sales_data;

-- checking distinct values 
SELECT DISTINCT STATUS FROM sales_data;
SELECT DISTINCT YEAR_ID FROM sales_data;
SELECT DISTINCT PRODUCTLINE FROM sales_data;
SELECT DISTINCT COUNTRY FROM sales_data;
SELECT COUNT(DISTINCT(COUNTRY)) FROM sales_data;
SELECT DISTINCT TERRITORY FROM sales_data;
SELECT DISTINCT DEALSIZE FROM sales_data;
SELECT DISTINCT MONTH_ID FROM sales_data WHERE YEAR_ID = 2003;

-- ANALYSIS 
-- SALES BY PRODUCTLINE 
-- TOTAL SALES 
SELECT PRODUCTLINE, SUM(SALES) TOT_REVENUE 
FROM sales_data
GROUP BY PRODUCTLINE
ORDER BY 2 DESC; 

-- AVERAGE SALES BY PRODUCTLINE 
SELECT PRODUCTLINE, AVG(SALES) AVG_REVENUE 
FROM sales_data
GROUP BY PRODUCTLINE
ORDER BY 2 DESC; 

-- TOTAL SALES PER YEAR
SELECT YEAR_ID, SUM(SALES) TOT_REVENUE 
FROM sales_data
GROUP BY YEAR_ID
ORDER BY 2 DESC; 

-- TOTAL SALES BY DEAL SIZE 
SELECT DEALSIZE, SUM(SALES) TOT_REVENUE
FROM sales_data
GROUP BY DEALSIZE
ORDER BY 2 DESC;

-- BEST MONTH FOR SALES IN YEAR 2003 AND HOW MUCH EARNED? 
SELECT MONTH_ID, SUM(SALES) TOT_REVENUE, COUNT(ORDERNUMBER) FREQUENCY
FROM sales_data
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC;
-- BEST MONTH FOR SALES IN YEAR 2004 AND HOW MUCH EARNED?
SELECT MONTH_ID, SUM(SALES) TOT_REVENUE, COUNT(ORDERNUMBER) FREQUENCY 
FROM sales_data
WHERE YEAR_ID = 2004 
GROUP BY MONTH_ID 
ORDER BY 2 DESC;
-- BEST MONTH FOR SALES IN YEAR 2005 AND HOW MUCH EARNED?
SELECT MONTH_ID, SUM(SALES) TOT_REVENUE, COUNT(ORDERNUMBER) FREQUENCY
FROM sales_data
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID 
ORDER BY 2 DESC;
-- NOVEMBER HAS HIGHEST SALES AMONG ALL MONTHS. WHAT PRODUCT WAS SOLD IN NOVEMBER? 
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) TOT_REVENUE, COUNT(ORDERNUMBER) FREQUENCY 
FROM sales_data
WHERE YEAR_ID = 2004 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

-- RFM ANALYSIS TO UNDERSTAND CUSTOMER BEHAVIOUR AND PERFORM CUSTOMER SEGMENTATION 
-- R:RECENCY(LAST ORDER DATE) , F:FREQUENCY(TOTAL ORDERS), M:MONETARY(TOTAL SALES) 
-- WHO IS THE BEST CUSTOMER? 
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
SELECT CUSTOMERNAME, 
	SUM(SALES) MonetaryValue,
	AVG(SALES) AvgMonetaryValue, 
	COUNT(ORDERNUMBER) Frequency, 
	MAX(ORDERDATE) Last_Order_Date,  
(SELECT MAX(ORDERDATE) FROM sales_data) Max_Order_Date,
DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data)) Recency
FROM sales_data
GROUP BY CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--What products are most often sold together? 
--select * from sales_data where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sales_data p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from sales_data s
order by 2 desc; 


---EXTRAs----
--Which CITY has the highest number of SALES in the UK?
select CITY, sum (SALES) Revenue
from sales_data
where COUNTRY = 'UK'
group by CITY
order by 2 desc; 

---What is the best product in the United Kingdom?
select COUNTRY, YEAR_ID, PRODUCTLINE, sum(SALES) Revenue
from sales_data
where COUNTRY = 'UK'
group by  COUNTRY, YEAR_ID, PRODUCTLINE
order by 4 desc; 


