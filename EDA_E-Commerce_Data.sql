/*
E-Commerce Data
Actual transactions from UK retailer
*/


-- Clean up the dataset.
CREATE VIEW `practice-project-323312.Ecommerce_Data.newdata` AS
WITH CTE AS
    (
    SELECT 
        *, CAST(CustomerID AS STRING) AS CustID,
        ROUND(Quantity*UnitPrice,2) AS TotalPrice,
        FORMAT_DATE("%A", InvoiceDate) AS Weekday,
        FORMAT_DATE("%B %Y", InvoiceDate) AS Month
    FROM 
        `practice-project-323312.Ecommerce_Data.data`
    WHERE 
        Country = "United Kingdom" AND Description IS NOT NULL 
        AND UPPER(Description) = Description AND Description NOT LIKE "%?%"
        AND Description NOT LIKE "%POSTAGE%" AND Description NOT LIKE "%SAMPLES%"
        AND Description NOT LIKE "%CHECK%" AND Description NOT LIKE "%DOTCOM%"
    )
SELECT * EXCEPT (CustomerID, CustID), 
IFNULL(CustID, "Not Specified") AS Cust_ID, 
FROM CTE;

-- Check the transformed data  
SELECT *
FROM `practice-project-323312.Ecommerce_Data.newdata`;

-- Now analyze
-- The most sold products
SELECT Month, Description, SUM(Quantity) AS QTY
FROM `practice-project-323312.Ecommerce_Data.newdata`
GROUP BY Month, Description
ORDER BY Month, QTY DESC;

-- The product that generates the most sales 
SELECT Month, Description, ROUND(SUM(TotalPrice),2) AS Sales
FROM `practice-project-323312.Ecommerce_Data.newdata`
GROUP BY Month, Description
ORDER BY Month, Sales DESC;

-- The most sold products by frequency
SELECT Month, Description, COUNT(Description) AS Frequency
FROM `practice-project-323312.Ecommerce_Data.newdata`
WHERE Quantity > 0
GROUP BY Month, Description
ORDER BY Month, Frequency DESC;

-- Products that give a negative response (refund by Frequency) 
SELECT Month, Description, COUNT(Description) AS Frequency
FROM `practice-project-323312.Ecommerce_Data.newdata`
WHERE Quantity < 0
GROUP BY Month, Description
ORDER BY Month, Frequency DESC;

-- Average buying per day by InvoiceNo (frequency)
SELECT Month, Weekday, CEIL(AVG(QtyNum)) AS AverageBuy
FROM(
    SELECT Invoice_Date, Weekday, COUNT(InvoiceNo) AS QtyNum, Month
    FROM(
        SELECT CAST(InvoiceDate AS date) AS Invoice_Date, InvoiceNo, Weekday, Month
        FROM `practice-project-323312.Ecommerce_Data.newdata`
        GROUP BY Invoice_Date, InvoiceNo, Weekday, Month
        ORDER BY Invoice_Date
        )
    GROUP BY Invoice_Date, Weekday, Month
    ORDER BY QtyNum
    )
GROUP BY Month,Weekday
ORDER BY Month;

-- Customers who buy the most (by total quantity)
SELECT Month, Cust_ID, SUM(Quantity) AS TotalBuy
FROM `practice-project-323312.Ecommerce_Data.newdata`
WHERE Cust_ID != "Not Specified"
GROUP BY Month, Cust_ID
ORDER BY Month, TotalBuy DESC;

-- Customers who buy the most (by frequency)
SELECT Month, Cust_ID, COUNT(InvoiceNo) AS Frequency
FROM(
    SELECT InvoiceDate, InvoiceNo, Cust_ID, Month
    FROM `practice-project-323312.Ecommerce_Data.newdata`
    WHERE Cust_ID != "Not Specified"
    GROUP BY InvoiceDate, InvoiceNo, Cust_ID, Month
    ORDER BY InvoiceDate
    )
GROUP BY Month, Cust_ID
ORDER BY Month, Frequency DESC;

-- The time of the most buyers 
WITH CTE2 AS
    (SELECT Invoice_Date, InvoiceNo, Times, Month, 
        CASE 
        WHEN Times BETWEEN "05:00:00" AND "11:59:00" THEN "Morning"
        WHEN Times BETWEEN "12:00:00" AND "17:00:00" THEN "Afternoon"
        WHEN Times BETWEEN "17:01:00" AND "21:00:00" THEN "Evening"
        ELSE "Night"
        END AS TimeBuying
    FROM(
        SELECT 
            CAST(InvoiceDate AS date) AS Invoice_Date, InvoiceNo, 
            CAST(InvoiceDate AS time) AS Times, Month
        FROM `practice-project-323312.Ecommerce_Data.newdata`
        WHERE Quantity > 0
        GROUP BY Invoice_Date, Times, InvoiceNo, Month 
        )
    ORDER BY Month, Times)
SELECT Month, TimeBuying, COUNT(InvoiceNo) AS Purchase
FROM CTE2
GROUP BY Month, TimeBuying
ORDER BY Month, Purchase DESC;