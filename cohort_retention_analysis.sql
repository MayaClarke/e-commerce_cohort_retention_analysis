/*

E-commerce Cohort Retention Analysis

*/

--- Cleaning Data

-- Total Records = 541909
-- 135080 Records have no CustomerID
-- 406829 Records have CustomerID

;WITH online_retail AS
(
    SELECT [InvoiceNo]
        ,[StockCode]
        ,[Description]
        ,[Quantity]
        ,[InvoiceDate]
        ,[UnitPrice]
        ,[CustomerID]
        ,[Country]
    FROM [tempdb].[dbo].[Online_Retail]
    WHERE CustomerID IS NOT NULL
), quantity_unit_price AS
(

    -- 397882 records with quantity and unit price 
    SELECT *
    FROM online_retail
    WHERE Quantity > 0 AND UnitPrice > 0
 )
, dup_check AS
(
    -- duplicate check
    SELECT *, ROW_NUMBER() OVER (PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) dup_flag
    FROM quantity_unit_price
)
-- 397667 clean data
-- 5215 duplicate records
SELECT *
 INTO #online_retail_main
FROM dup_check
WHERE dup_flag = 1

-- Clean Data
-- BEGIN COHORT ANALYSIS
SELECT * 
FROM #online_retail_main


-- Unique Identifier (CustomerId)
-- Initial Start Date (First InvoiceDate)
-- Revenue Date

SELECT
	CustomerID,
	min(InvoiceDate) first_purchase_date,
	DATEFROMPARTS(year(min(InvoiceDate)), month(min(InvoiceDate)), 1) Cohort_Date
INTO #cohort
FROM #online_retail_main
GROUP BY CustomerID

SELECT *
FROM #cohort

-- Create Cohort Index
select
	mmm.*,
	cohort_index = year_diff * 12 + month_diff + 1
into #cohort_retention
from
	(
		select
			mm.*,
			year_diff = invoice_year - cohort_year,
			month_diff = invoice_month - cohort_month
		from
			(
				select
					m.*,
					c.Cohort_Date,
					year(m.InvoiceDate) invoice_year,
					month(m.InvoiceDate) invoice_month,
					year(c.Cohort_Date) cohort_year,
					month(c.Cohort_Date) cohort_month
				from #online_retail_main m
				left join #cohort c
					on m.CustomerID = c.CustomerID
			)mm
	)mmm
-- WHERE CustomerId = 14733


-- Pivot Data to see cohort table
select 	*
into #cohort_pivot
from(
	select distinct 
		CustomerID,
		Cohort_Date,
		cohort_index
	from #cohort_retention
)tbl
pivot(
	Count(CustomerID)
	for Cohort_Index In 
		(
		[1], 
        [2], 
        [3], 
        [4], 
        [5], 
        [6], 
        [7],
		[8], 
        [9], 
        [10], 
        [11], 
        [12],
		[13])

)as pivot_table

select *
from #cohort_pivot
order by Cohort_Date

select Cohort_Date ,
	(1.0 * [1]/[1] * 100) as [1], 
    1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12],  
	1.0 * [13]/[1] * 100 as [13]
from #cohort_pivot
order by Cohort_Date