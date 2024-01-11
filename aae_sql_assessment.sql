*/
Problem overview:
We are HP CRM management team. We have to design a targeted campaign focusing on certain set of customers. For this, we want to understand past performance and know certain hp KPIs that will help us in building this campaign. The data provided is transactional data from HP store for 5 years that means every row is an item in an order placed by a customer. You will have to download the data, upload it in your local SQL environment and answer the following questions using SQL. Please provide a brief write-up on the questions along with SQL codes and inline commments that you would have used to respond to the question. For SQL queries, you can use CTE’s or temp tables as per the need.

Data Repository: 
Data.sql (part of zip file) file contains all SQL for table creation and data insertion. 

Data Dictionary: 
NOTE: One customer can have multiple orders in which case the same email id will have multiple order numbers associated to it. Similarly, An order can have one or multiple products. In case of multiple products in the order, the order number will be the same but the product_sku will be different.
As per above - Each row represents 1 item of an order

email_id - customer who placed the order
country - country to which the customer belonged
order_number - the order number of the order
order_creation_date - date along with timestamp denoting the date and time on which the order was placed
order_type - if the order was placed on website(web) or through telesales(ts)
customer_segment - If the customer was an individual (consumer) or working for a business (Business)
product_sku - the product identifier
product_category_id – ID of the Product type (ex. Laptop, desktop, printer, supply, accessory etc.) purchased
quantity - units purchased corresponding to product_number_option purchased
revenue - total revenue corresponding to product_number_option purchased

 
Data analysis questions:
1.	Does the data require cleaning (missing values/outlier treatment etc.)? 
a.	if no, how did you assess that the data is clean? 
b.	if yes clean the data as per your understanding and proceed with clean data. 
2.	How has hp.com been performing over the years? 
a.	Compare the sales volumes, total revenue, number of orders and exact count of customers across years.
b.	Detect trends at week level across the years
c.	product_category_id sales volume variation – Any trend?
3.	Segment all customers in the data using the following rules. The groups should be mutually exclusive i.e. one customer should fall only in one group and higher ranked group gets priority (ex. If a customer falls in group 1 and group 3 then group 1 gets priority)
a.	Group 1: Customers with >2000 total revenue in last 1 year
b.	Group 2: Customers with >2000 total revenue in last 2 years
c.	Group 3: Customers with >2000 total revenue in any 2 consecutive years (in the entire data provided)
d.	Group 4: Customers with <2000 in last 2 years
e.	Group 5: Customers from the complete set with 0 revenue in last 2 years 
4.	What has been the yearly_quarterly trends for the following.
a.	acquisition rate (customers placing their first order with HP)
b.	repeat rate (customers placing any order after the first order with HP)
c.	drop rate (cust who haven’t placed an order with HP in 2 consecutive years) 
Note: As most of the questions are open-ended data exploration, logical approach to the solution and coding skills will be looked at closely while evaluation. Hence, though the results need to make business sense, actual 'correctness' of the results bear less importance. 

Submission format
We require the following from you:
1. pgSQL code with succinct inline comments
2. A brief write-up explaining how you went about the steps and data analysis and observations.

Please try to spend no more than two days on this. 
Thank You!!!
*/

--00-PRE-CHECKING  ============================================================================

--TEST TABLE CONTENT
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
FROM public.sql_test limit 10;

--COUNT TABLE CONTENT --> result:1656911 The table has been correctly populated
SELECT COUNT(1) from public.sql_test ;


--PART--01-CLEANSING ============================================================================
/*1.Does the data require cleaning (missing values/outlier treatment etc.)? 
  1. a.	if no, how did you assess that the data is clean? */

--1. a. qry-01 The field 'country' is not populated
SELECT COUNT(1) from public.sql_test where country is not NULL; --> result:1656911
SELECT COUNT(1) from public.sql_test where country is NULL; --> result:0

--Remark: the field 'revenue' contains somes value = 0
--
--|email_id |country|order_number                    |order_creation_date    |order_type|customer_segment|product_category_id|product_sku                     |quantity|revenue|
--|---------|-------|--------------------------------|-----------------------|----------|----------------|-------------------|--------------------------------|--------|-------|
--|2,125,403|       |23feb154b7f6a34cd88deced1b7bdc07|2015-04-18 14:48:03.000|Web       |Consumer        |                   |90c4c5e25a9aeacb4ce4244d5c762da0|1       |9.85   |
--|807,354  |       |ab95782c94e1bd03217172dc12820c4c|2013-02-28 13:04:49.000|Web       |Business        |                   |90c4c5e25a9aeacb4ce4244d5c762da0|1       |0      |
--|5,521,910|       |636c2c75222f72e3085559b91a10dd41|2012-12-21 11:09:44.000|Web       |Consumer        |                   |90c4c5e25a9aeacb4ce4244d5c762da0|1       |0      |

--1. a. qry02 - There are 166095 records where field 'revenue' contains value = 0
SELECT COUNT(1) from public.sql_test WHERE revenue = 0

--1. a. qry03 - See a random example from the file data.sql, the second column is set as NULL
--..
INSERT INTO sql_test (email_id, country, order_number, order_creation_date, order_type, customer_segment, product_sku, quantity, revenue, product_category_id) 
VALUES (940999, null, '9d969d9c50675a6026034bd0a954db33', '2013-01-10 08:33:12.000000', 'Web', 'Consumer', '90c4c5e25a9aeacb4ce4244d5c762da0', 1, 0, null);
--..

--1. a. qry04 - Sample check if duplicated -- It is OK as first approach
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
FROM public.sql_test WHERE email_id = 940999;

--|email_id|country|order_number                    |order_creation_date    |order_type|customer_segment|product_category_id|product_sku                     |quantity|revenue|
--|--------|-------|--------------------------------|-----------------------|----------|----------------|-------------------|--------------------------------|--------|-------|
--|940,999 |       |9d969d9c50675a6026034bd0a954db33|2013-01-10 08:33:12.000|Web       |Consumer        |1                  |36005b574bb9d4d7775f3175867cb96b|2       |293.61 |
--|940,999 |       |9d969d9c50675a6026034bd0a954db33|2013-01-10 08:33:12.000|Web       |Consumer        |                   |90c4c5e25a9aeacb4ce4244d5c762da0|1       |0      |


--1. a. qry05 - Check duplicate accuracy as second approach, with a first method that I will NOT use for the Part 2.
SELECT concat(email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue)
FROM public.sql_test;

--1. a. qry06 --  Try to create a temp table 
CREATE TEMP TABLE t(tempo varchar); 

--1. a. qry07 -- and insert the fileds concatenation result
INSERT INTO t 
	(
	SELECT concat(email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue)
	FROM public.sql_test
	--Compare first approach and second approach. Is the count of record is the same.
	);

--1. a. qry08 - Create index to reduce time
CREATE INDEX inc1 on t USING BRIN (tempo); -- 'BRIN = block range indexes' a bit faster than than classical BTREE index on a very large table
--(to ignore) CREATE INDEX inc1 on t USING BTREE (tempo);--Drop index if needed -- DROP INDEX inc1;

--1. a. qry07 - Check if populated --> OK = 1656911 records
SELECT COUNT(1) FROM t ;

--1. a. qry08 - Extract a sample of 2 records that are duplicated (for example above 3 duplicates)
SELECT tempo, COUNT(tempo) FROM t GROUP BY  tempo  HAVING COUNT(tempo) > 3 limit 2;
--|tempo                                                                                                        |count|
--|-------------------------------------------------------------------------------------------------------------|-----|
--|3965093fecb1f611a8cf97e7aaf8f35c3ebeaf52014-09-12 13:23:55WebBusiness2157969e8d05da0ec418e3eb44ac4184a1717.87|5    |
--|5238235c1ed8b1c5f6c5db658493bf5b22a89762013-04-04 16:18:34WebConsumer668bf44f5289375157432eb9195a12cbb153.7  |4    |

--1. a. qry09 - Index sql_test tabl
CREATE INDEX ins2 on public.sql_test USING BTREE (email_id);


--1. a. qry10 - Confirm observation with one of these sample
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
FROM public.sql_test 
 WHERE email_id = '5238235' AND order_number = 'c1ed8b1c5f6c5db658493bf5b22a8976' AND product_sku = '68bf44f5289375157432eb9195a12cbb';




--here a sample where it has 4 duplicate as found in table 't'
--|email_id |country|order_number                    |order_creation_date    |order_type|customer_segment|product_category_id|product_sku                     |quantity|revenue|
--|---------|-------|--------------------------------|-----------------------|----------|----------------|-------------------|--------------------------------|--------|-------|
--|5,238,235|       |c1ed8b1c5f6c5db658493bf5b22a8976|2013-04-04 16:18:34.000|Web       |Consumer        |6                  |68bf44f5289375157432eb9195a12cbb|1       |53.7   |
--|5,238,235|       |c1ed8b1c5f6c5db658493bf5b22a8976|2013-04-04 16:18:34.000|Web       |Consumer        |6                  |68bf44f5289375157432eb9195a12cbb|1       |53.7   |
--|5,238,235|       |c1ed8b1c5f6c5db658493bf5b22a8976|2013-04-04 16:18:34.000|Web       |Consumer        |6                  |68bf44f5289375157432eb9195a12cbb|1       |53.7   |
--|5,238,235|       |c1ed8b1c5f6c5db658493bf5b22a8976|2013-04-04 16:18:34.000|Web       |Consumer        |6                  |68bf44f5289375157432eb9195a12cbb|1       |53.7   |

--1. a. qry11 - Index 'ins2' has reacted but I need more time to improve this query performance.
EXPLAIN SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
FROM public.sql_test 
WHERE email_id = '5238235' AND order_number = 'c1ed8b1c5f6c5db658493bf5b22a8976' AND product_sku = '68bf44f5289375157432eb9195a12cbb';

--|QUERY PLAN                                                                                                                        |
--|----------------------------------------------------------------------------------------------------------------------------------|
--|Index Scan using ins2 on sql_test  (cost=0.43..32.58 rows=1 width=144)                                                            |
--|  Index Cond: (email_id = '5238235'::bigint)                                                                                      |
--|  Filter: ((order_number = 'c1ed8b1c5f6c5db658493bf5b22a8976'::text) AND (product_sku = '68bf44f5289375157432eb9195a12cbb'::text))|



--1. a. qry10 - Drop index
DROP INDEX ins2;

--1. a. qry11 - COUNT How many rows are duplicated -- I find 5910 records, hence 1656911 - 1650496 = 6415, .. a small difference that will NOT carry on with with this method. 
-- Insteadl I will use the ROW_NUMBER () method detailled further... 

--1. a. qry12 - test 1
SELECT COUNT(distinct tempo) FROM t; -- = 1650496

--1. a. qry13 - test 2
SELECT COUNT(1) FROM  (SELECT tempo, COUNT(tempo) FROM t GROUP BY  tempo  HAVING COUNT(tempo) > 1) b; -- = 5910 I abandon this way then.




--1. b.	if yes clean the data as per your understanding and proceed with clean data. 

--1. b. qry01 - Sample test to increment the duplicated rows
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue,
ROW_NUMBER() OVER(
    PARTITION BY email_id,order_number,product_sku 
    ORDER BY email_id, order_number,product_sku 
)
 FROM public.sql_test
 where email_id = '5238235' AND order_number = 'c1ed8b1c5f6c5db658493bf5b22a8976'

----1. b. qry01 - From below query, I am getting same result as above (in one 1. a. ) = 6415
SELECT COUNT(1) from (
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue,
ROW_NUMBER() OVER(
    PARTITION BY email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
    ORDER BY email_id, order_number,product_sku 
)
 AS rd
 FROM public.sql_test
)a
WHERE a.rd > 1;

----1. b. qry01 - Create a new table 'public.sql_test_clean' where I will keep the cleansed data
CREATE TABLE public.sql_test_clean (
	email_id int8 NULL,
	country text NULL,
	order_number text NULL,
	order_creation_date timestamp NULL,
	order_type text NULL,
	customer_segment text NULL,
	product_category_id int4 NULL,
	product_sku text NULL,
	quantity int8 NULL,
	revenue numeric null,
	rd INT 
);

--1. b. qry02 -
INSERT INTO public.sql_test_clean
(email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue, rd)

(
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue,
ROW_NUMBER() OVER(
    PARTITION BY email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
    ORDER BY email_id, order_number,product_sku 
)
 AS rd
 FROM public.sql_test
);

--1. b. qry03 -
CREATE INDEX inscl2 ON public.sql_test_clean  USING btree (rd);

--1. b. qry04--Delete 6415 rows
DELETE FROM public.sql_test_clean WHERE rd > 1;

--1. b. qry05 - Test if duplicates gones. I find 1650496 records! Hence, total 1656911 - 6415 duplicates records = 1650496 records. It is then correct.
SELECT COUNT(1) from 
(
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
FROM public.sql_test_clean stc 
)f


 
--02--DATA ANALYSIS (REVENUES) ============================================================================

--!!! As the logic is priviligied in this exercice i will keep using the table sql_test instead of the table sql_test_clean. Furhtermore the duplicates do not impact strongly the trends.

-- 2. a. - How has hp.com been performing over the years? 
-- I do not find this data, but it seems we are talking about the company owner itself. I checked in case of ..

-- 2. a. qry01 testing from shell and then SQL
--alain@osboxes:~/Documents$ cat data.sql | grep hp.com
--alain@osboxes:~/Documents$ cat data.sql | grep hp
--alain@osboxes:~/Documents$ cat data.sql | grep *hp*
--alain@osboxes:~/Documents$ cat data.sql | grep com
SELECT * FROM public.sql_test WHERE customer_segment LIKE '%hp%';
SELECT * FROM public.sql_test WHERE order_type  LIKE '%hp%';
SELECT * FROM public.sql_test WHERE order_number  LIKE '%hp%';
 
 
-- 2. a.	Compare the sales volumes, total revenue, number of orders and exact count of customers across years.

-- 2. a. qry02 -- Here is the result
SELECT date_part('YEAR',order_creation_date), COUNT(order_number) AS ct_order,COUNT(distinct customer_segment) AS ct_cr_sgmt, COUNT(product_sku) AS ct_product, SUM(quantity) AS sum_all_qty , SUM(revenue) AS sum_revenue
FROM public.sql_test
GROUP BY  date_part('YEAR',order_creation_date);

--|date_part|ct_order|ct_cr_sgmt|ct_product|sum_all_qty|sum_revenue   |
--|---------|--------|----------|----------|-----------|--------------|
--|2,012    |107,148 |2         |107,148   |121,541    |46,325,639.69 |
--|2,013    |357,858 |2         |357,858   |418,296    |130,774,876.16|
--|2,014    |293,708 |2         |293,708   |359,768    |175,282,802.08|
--|2,015    |424,925 |2         |424,925   |533,314    |197,756,808.74|
--|2,016    |473,272 |2         |473,272   |580,978    |209,380,031.49|


-- 2. b.	Detect trends at week level across the years
 
-- The result from 2. a. qry02 shows an increase smothly from 2012 to 2016 for the revenues
-- 2013 had more quantity of products solds than 2014 whereas the revenues increased


-- 2. b. qry03 -- The field 'customer_segment is not releveant as we found just 2 categories everywhere.
 SELECT distinct  customer_segment
FROM public.sql_test
WHERE date_part('YEAR',order_creation_date) ='2012';
 
-- |customer_segment|
--|----------------|
--|Business        |
--|Consumer        |

--2. b. qry04 -- It is better if we use the email_id -- > then the number of customer correlate with the revenues curve.
SELECT date_part('YEAR',order_creation_date), COUNT(distinct email_id) as ct_email_id,COUNT(order_number) AS ct_order,COUNT(distinct customer_segment) AS ct_cr_sgmt, COUNT(product_sku) AS ct_product, SUM(quantity) AS sum_all_qty , SUM(revenue) AS sum_revenue
FROM public.sql_test
GROUP BY  date_part('YEAR',order_creation_date)

--|date_part|ct_email_id|ct_order|ct_cr_sgmt|ct_product|sum_all_qty|sum_revenue   |
--|---------|-----------|--------|----------|----------|-----------|--------------|
--|2,012    |34,738     |107,148 |2         |107,148   |121,541    |46,325,639.69 |
--|2,013    |97,132     |357,858 |2         |357,858   |418,296    |130,774,876.16|
--|2,014    |140,913    |293,708 |2         |293,708   |359,768    |175,282,802.08|
--|2,015    |200,174    |424,925 |2         |424,925   |533,314    |197,756,808.74|
--|2,016    |224,446    |473,272 |2         |473,272   |580,978    |209,380,031.49|

--2. b. qry04 -- compared with the sql_test_clean table, result difference are meanless, hence I will further keep going with sql_test table. 
SELECT date_part('YEAR',order_creation_date), COUNT(distinct email_id) as ct_email_id,COUNT(order_number) AS ct_order,COUNT(distinct customer_segment) AS ct_cr_sgmt, COUNT(product_sku) AS ct_product, SUM(quantity) AS sum_all_qty , SUM(revenue) AS sum_revenue
FROM public.sql_test_clean
GROUP BY  date_part('YEAR',order_creation_date)

--|date_part|ct_email_id|ct_order|ct_cr_sgmt|ct_product|sum_all_qty|sum_revenue   |
--|---------|-----------|--------|----------|----------|-----------|--------------|
--|2,012    |34,738     |106,613 |2         |106,613   |120,996    |46,198,944.87 |
--|2,013    |97,132     |355,874 |2         |355,874   |416,204    |130,150,162.65|
--|2,014    |140,913    |291,979 |2         |291,979   |357,975    |174,752,650.75|
--|2,015    |200,174    |423,900 |2         |423,900   |532,125    |197,643,830.55|
--|2,016    |224,446    |472,130 |2         |472,130   |579,744    |209,284,802.35|


-- 2. c.	product_category_id sales volume variation – Any trend?

--2. c. qry01 -- -- The volume of product_category_id correlate with the revenues trend increase.
SELECT date_part('YEAR',order_creation_date), COUNT(product_category_id) as ct_prd_id ,COUNT(order_number) AS ct_order,COUNT(distinct customer_segment) AS ct_cr_sgmt, COUNT(product_sku) AS ct_product, SUM(quantity) AS sum_all_qty , SUM(revenue) AS sum_revenue
FROM public.sql_test
GROUP BY  date_part('YEAR',order_creation_date)

--|date_part|ct_prd_id|ct_order|ct_cr_sgmt|ct_product|sum_all_qty|sum_revenue   |
--|---------|---------|--------|----------|----------|-----------|--------------|
--|2,012    |68,036   |107,148 |2         |107,148   |121,541    |46,325,639.69 |
--|2,013    |234,040  |357,858 |2         |357,858   |418,296    |130,774,876.16|
--|2,014    |289,552  |293,708 |2         |293,708   |359,768    |175,282,802.08|
--|2,015    |411,523  |424,925 |2         |424,925   |533,314    |197,756,808.74|
--|2,016    |460,368  |473,272 |2         |473,272   |580,978    |209,380,031.49|


--03--DATA-ANALYSIS (CATEGORY REVENUES)  ============================================================================

--3.	Segment all customers in the data using the following rules. The groups should be mutually exclusive i.e. one customer should fall only in one group and higher ranked group gets priority (ex. If a customer falls in group 1 and group 3 then group 1 gets priority)

--3. a.	qry01 -- Group 1: Customers with >2000 total revenue in last 1 year- --> result = 26360 records
SELECT COUNT(1) FROM
(
SELECT email_id, SUM(revenue) AS sum_revenue_categ
FROM public.sql_test
WHERE date_part('YEAR',order_creation_date) ='2016'
GROUP BY email_id
HAVING SUM(revenue) > 2000
)a;

--3. b.	qry01 -- Group 2: Customers with >2000 total revenue in last 2 year --> result = 51281 records
SELECT COUNT(1) FROM
(
SELECT email_id, SUM(revenue) AS sum_revenue_categ
FROM public.sql_test
WHERE date_part('YEAR',order_creation_date) >'2014'
GROUP BY email_id
HAVING SUM(revenue) > 2000
)b;

--3. c.	qry01 -- Group 3: Customers with >2000 total revenue in any 2 consecutive years (in the entire data provided)
-- I dont understand the question, because you do not explicitely stipulate from which year I should segment the data, in a set of 2 years.


--3. d.	qry01 -- Group 4: Customers with <2000 in last 2 years --> result: 331134 records
SELECT COUNT(1) FROM
(
SELECT email_id, SUM(revenue) AS sum_revenue_categ
FROM public.sql_test
WHERE date_part('YEAR',order_creation_date) > '2014'
GROUP BY email_id
HAVING SUM(revenue) < 2000
)d;

--3. e.	qry01 -- Group 5: Customers from the complete set with 0 revenue in last 2 years 
-- --> result : 14 records
SELECT email_id, SUM(revenue) AS sum_revenue_categ
FROM public.sql_test
GROUP BY email_id
HAVING SUM(revenue) = 0

--3. e.	qry02 -- Furher confirmation with these following below samples:
SELECT email_id, country, order_number, order_creation_date, order_type, customer_segment, product_category_id, product_sku, quantity, revenue
FROM public.sql_test 
 WHERE email_id IN ('504160','2852319','1763917','2731410','2016795') 
 
 --|email_id |country|order_number                    |order_creation_date    |order_type|customer_segment|product_category_id|product_sku                     |quantity|revenue|
--|---------|-------|--------------------------------|-----------------------|----------|----------------|-------------------|--------------------------------|--------|-------|
--|504,160  |       |9b77b8bf6836593754f227272f61adbd|2015-07-30 21:15:34.000|Web       |Consumer        |6                  |9e8510b36bbc0253aa18c90c41959566|2       |0      |
--|2,016,795|       |2f785ab7e8d5e17390642a0160ed02a8|2015-05-13 11:19:33.000|TS        |Business        |16                 |ea48213f8602b76e1371db975d909c19|1       |0      |
--|2,731,410|       |1dc94bb17b203d35d66f4c82758cf1d7|2016-07-30 15:20:24.000|Web       |Consumer        |1                  |2b8a2140ff7dccb86bda61a3cb868344|1       |0      |
--|2,852,319|       |222f8f51bd498afd44d7f9e681601909|2016-07-30 14:25:02.000|Web       |Consumer        |1                  |bb2abb6ff0fb0f59ed5fa7ba8f417bfd|1       |0      |
--|1,763,917|       |07f9bb01d826ac3ad4b0756811718331|2016-07-30 17:10:52.000|Web       |Consumer        |1                  |2b8a2140ff7dccb86bda61a3cb868344|1       |0      |
--|2,016,795|       |2f785ab7e8d5e17390642a0160ed02a8|2015-05-13 11:19:33.000|TS        |Business        |7                  |74c0c17c16c3bafe56b5b9288707f8a3|1       |0      |


 -- 4.	What has been the yearly_quarterly trends for the following.
 --4. a.	acquisition rate (customers placing their first order with HP)

 --4. a. qry01 -- A We need to look each customer and segment each of them by year and quarter. For example the email_id '1676' has ordered at 6 diferent segments ( YEAR & QUARTER)

 SELECT * ,
 
 ROW_NUMBER() OVER(
    PARTITION BY r.email_id
    ORDER BY r.y_ord, r.qrt_ord,r.email_id  
)
 FROM
		(
		SELECT distinct email_id, date_part('YEAR',order_creation_date) as Y_ord, date_part('QUARTER',order_creation_date) AS qrt_ord--, --, COUNT(order_number)
		FROM public.sql_test 
		)r
WHERE r.email_id =  1676 

--|email_id|y_ord|qrt_ord|row_number|
--|--------|-----|-------|----------|
--|1,676   |2,013|4      |1         |
--|1,676   |2,014|1      |2         |
--|1,676   |2,014|3      |3         |
--|1,676   |2,015|3      |4         |
--|1,676   |2,016|1      |5         |


--4. a. qry02 -- if we check the sample on the raw table 'sql_test' for email_id = 1676 the result is coherent.
 SELECT email_id, order_number, order_creation_date FROM sql_test WHERE email_id =  1676 ORDER BY 3

 --|email_id|order_number                    |order_creation_date    | SEGMENT
--|--------|--------------------------------|-----------------------|
--|1,676   |548387c891399ec0ea071fc957a57b0c|2013-12-06 13:39:39.000|1
--|1,676   |548387c891399ec0ea071fc957a57b0c|2013-12-06 13:39:39.000|1
--|1,676   |56c3e0c395d4984d223be7772eb4f34a|2014-02-10 16:37:07.000|2
--|1,676   |b3a61641053afd43041c6b0a0140029f|2014-07-21 18:58:52.000|3
--|1,676   |4d7af9b738148a75176105b17d2f31d2|2015-07-21 09:25:28.000|4
--|1,676   |799b63316c3112a43bd11fd9e5f71943|2016-01-12 18:58:58.000|5
--|1,676   |799b63316c3112a43bd11fd9e5f71943|2016-01-12 18:58:58.000|5
--|1,676   |799b63316c3112a43bd11fd9e5f71943|2016-01-12 18:58:58.000|5
--|1,676   |799b63316c3112a43bd11fd9e5f71943|2016-01-12 18:58:58.000|5
--|1,676   |799b63316c3112a43bd11fd9e5f71943|2016-01-12 18:58:58.000|5
 
 --4. a. qry03 -- Calcultation adquisition rate - COUNT of new customer by SEGMENT (Year + quater) by customer -- 
 	--As a result we see an increasing tendency of new customer, exept for 2013 Q1 Q2 Q3 and another slight decrease in 2024 Q1 Q2 
 
  SELECT A.y_ord, A.qrt_ord, COUNT(distinct email_id) as ct_new_customer
   FROM
	( 
   SELECT * ,
	 
	 ROW_NUMBER() OVER(
	    PARTITION BY r.email_id
	    ORDER BY r.y_ord, r.qrt_ord,r.email_id
	)  AS ct_segmt
	 FROM
			(
			SELECT distinct email_id, date_part('YEAR',order_creation_date) as Y_ord, date_part('QUARTER',order_creation_date) AS qrt_ord--, --, COUNT(order_number)
			FROM public.sql_test 
			)r
	)A		
	 WHERE A.ct_segmt = 1
	 GROUP BY A.y_ord, A.qrt_ord

	 
--|y_ord|qrt_ord|ct_new_customer |
--|-----|-------|------|
--|2,012|1      |10    |
--|2,012|3      |9,533 |
--|2,012|4      |25,195|
--|2,013|1      |22,164|
--|2,013|2      |24,396|
--|2,013|3      |18,496|
--|2,013|4      |25,934|
--|2,014|1      |24,392|
--|2,014|2      |24,282|
--|2,014|3      |31,306|
--|2,014|4      |42,558|
--|2,015|1      |40,722|
--|2,015|2      |36,919|
--|2,015|3      |40,886|
--|2,015|4      |46,251|
--|2,016|1      |46,085|
--|2,016|2      |36,321|
--|2,016|3      |41,189|
--|2,016|4      |47,502|
	 
--4. b.	repeat rate (customers placing any order after the first order with HP)

--4. b. qry01 -- from below query and results, the trend is slightly positive	 
  SELECT A.y_ord, A.qrt_ord, COUNT(distinct email_id) as ct_repeat_customer
   FROM
	( 
   SELECT * ,
	 
	 ROW_NUMBER() OVER(
	    PARTITION BY r.email_id
	    ORDER BY r.y_ord, r.qrt_ord,r.email_id
	)  AS ct_segmt
	 FROM
			(
			SELECT distinct email_id, date_part('YEAR',order_creation_date) as Y_ord, date_part('QUARTER',order_creation_date) AS qrt_ord--, --, COUNT(order_number)
			FROM public.sql_test 
			)r
	)A		
	 WHERE A.ct_segmt > 1
	 GROUP BY A.y_ord, A.qrt_ord	 
/*
|y_ord|qrt_ord|ct_repeat_customer |
|-----|-------|------|
|2,012|2      |2     |
|2,012|3      |1     |
|2,012|4      |765   |
|2,013|1      |2,846 |
|2,013|2      |4,623 |
|2,013|3      |5,331 |
|2,013|4      |7,238 |
|2,014|1      |7,506 |
|2,014|2      |7,838 |
|2,014|3      |9,289 |
|2,014|4      |12,130|
|2,015|1      |14,672|
|2,015|2      |15,693|
|2,015|3      |17,755|
|2,015|4      |21,017|
|2,016|1      |22,367|
|2,016|2      |21,636|
|2,016|3      |22,990|
|2,016|4      |24,901|
*/
	 
--4. c.	drop rate (cust who haven’t placed an order with HP in 2 consecutive years) 
--!!! -- I did not achieve to create a parent segment for the 2 consecutive years but I can think how to do it if more times is given. 
-- Hence I only kept the logic for the segment : customer by segment (YEAR & QUARTER)
	 
--4. c. qry01 -- Create a temp table to stock new customer by segment (YEAR & QUARTER)	 
	 
 CREATE TEMP TABLE t_nw_cst(email_id INT);

--4. c. qry02 -- INSERT Into a table 't_nw_cst' containing new customer, based on previous query ref: '4. a. qry03'
 INSERT INTO t_nw_cst(email_id)
 SELECT distinct nw_cst.email_id
	from
	(
   SELECT * ,
	 
	 ROW_NUMBER() OVER(
	    PARTITION BY r.email_id
	    ORDER BY r.y_ord, r.qrt_ord,r.email_id)  AS ct_segmt
	 FROM
			(
			SELECT distinct email_id, date_part('YEAR',order_creation_date) as Y_ord, date_part('QUARTER',order_creation_date) AS qrt_ord--, COUNT(order_number)
			FROM public.sql_test 
			)r
			
	)nw_cst
	 WHERE nw_cst.ct_segmt = 1;

--4. c. qry03 -- Create a table to store the repeating customers refs (email_id).
 CREATE TEMP TABLE t_repeat_cst(email_id INT);

--4. c. qry04 -- Insert query results into the temp table ' t_repeat_cst'
 INSERT INTO t_repeat_cst(email_id)
	SELECT distinct repeat_cst.email_id
	from
	(
   SELECT * ,
	 
	 ROW_NUMBER() OVER(
	    PARTITION BY r.email_id
	    ORDER BY r.y_ord, r.qrt_ord,r.email_id
	)  AS ct_segmt
	 FROM
			(
			SELECT distinct email_id, date_part('YEAR',order_creation_date) as Y_ord, date_part('QUARTER',order_creation_date) AS qrt_ord--, --, COUNT(order_number)
			FROM public.sql_test 
			)r
	)repeat_cst
	WHERE repeat_cst.ct_segmt > 1		

--4. c. qry05 -- Index t_nw_cst to faster LEFT JOIN further explain on query '4. c. qry07': 
 CREATE UNIQUE INDEX ict1 ON 	t_nw_cst(email_id);

--4. c. qry06 -- Index t_repeat_cst to faster LEFT JOIN further explain on query '4. c. qry07': 
 CREATE UNIQUE INDEX icr1 ON 	t_repeat_cst(email_id);

--4. c. qry07 -- Compare both tables and see what is in the table new customer and substract the number of repeating customer
 SELECT n.email_id FROM t_nw_cst n LEFT JOIN t_repeat_cst r ON n.email_id = r.email_id  WHERE r.email_id IS NULL 

--4. c. qry08 -- create a temp table to fill with non repeating customers
CREATE TEMP TABLE t_non_repeat_cst(email_id INT);-- drop table t_non_repeat_cst;

--4. c. qry09 -- Populate the table 't_non_repeat_cst'
INSERT INTO  t_non_repeat_cst(email_id)
	SELECT n.email_id FROM t_nw_cst n LEFT JOIN t_repeat_cst r ON n.email_id = r.email_id  WHERE r.email_id IS NULL ;

--4. c. qry10 -- Speed up the JOIN in query '4. c. qry11'
CREATE UNIQUE INDEX inrct1 ON t_non_repeat_cst(email_id);

--4. c. qry11 -- SEE trends of non repeating customers -- It shows a very light increase per segment.
SELECT date_part('YEAR',order_creation_date) as Y_ord, date_part('QUARTER',order_creation_date) AS qrt_ord, COUNT(distinct s.email_id)
			FROM public.sql_test s
		   INNER	JOIN t_non_repeat_cst nr ON s.email_id =  nr.email_id 
		GROUP BY 	date_part('YEAR',order_creation_date), date_part('QUARTER',order_creation_date)
/*		
|y_ord|qrt_ord|count |
|-----|-------|------|
|2,012|1      |4     |
|2,012|3      |6,840 |
|2,012|4      |17,875|
|2,013|1      |15,159|
|2,013|2      |17,550|
|2,013|3      |13,403|
|2,013|4      |19,590|
|2,014|1      |18,394|
|2,014|2      |17,929|
|2,014|3      |23,698|
|2,014|4      |33,052|
|2,015|1      |30,471|
|2,015|2      |27,662|
|2,015|3      |32,292|
|2,015|4      |38,424|
|2,016|1      |38,986|
|2,016|2      |32,009|
|2,016|3      |38,135|
|2,016|4      |47,502|

*/	 

