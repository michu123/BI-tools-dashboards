USE [SelfLearn]
GO
---------------------------------------------  UPLOAD FLAT FILES  ---------------------------------------------------------------
--Load orginal data tables Online_Retail, Customer_Cohort, Customer_Segments thru task pane

---------------------------------------------  ORIGINAL SOURCE TRANSFORMATIONS --------------------------------------------------

/**** prepare original source for further data split ***/
ALTER TABLE [SelfLearn].[dbo].[Online_Retail]
DROP COLUMN [index];

--- new attribute InvoiceType creation ---
ALTER TABLE [SelfLearn].[dbo].[Online_Retail]
ADD [InvoiceType] [nvarchar] (10);

UPDATE [SelfLearn].[dbo].[Online_Retail] 
	SET [InvoiceType] = (SELECT CASE -- InvoiceNo with letter C are Credit invoice, the rest are Debit
				 WHEN [InvoiceNo] LIKE '%C%'
									  THEN 'Credit'
									  ELSE 'Debit'
				 END
				 ) 
	FROM [SelfLearn].[dbo].[Online_Retail];

--- attribute InvoiceNo transformation into integer data type ---
UPDATE [SelfLearn].[dbo].[Online_Retail] 
	SET [InvoiceNo] = (SELECT CASE -- letter C removed from InvoiceNo to make attribute integer data type
				 WHEN [InvoiceNo] LIKE '%C%'
									  THEN RIGHT([InvoiceNo], 6)
									  ELSE [InvoiceNo]
				 END
				 )
	FROM [SelfLearn].[dbo].[Online_Retail];

------------------------------------------------  DATABASE TABLES CREATION ------------------------------------------------------
/**** create & move distinct CustomerID to new Customers table from original source ***/
CREATE TABLE [SelfLearn].[dbo].[Customers] (
	[CustomerID] [int] NOT NULL PRIMARY KEY,
	[LastName] [nvarchar](100) NULL,
	[FirstName] [nvarchar](100) NULL,
	[Phone] [nvarchar](15) NULL,
	[Email] [nvarchar](200) NULL,
	[Country] [nvarchar](50) NULL,
	[Region] [nvarchar](50) NULL,
	[Continent] [nvarchar](50) NULL
);

INSERT INTO [SelfLearn].[dbo].[Customers] (
			[CustomerID],
			[Country],
			[Region],
			[Continent]
			)
SELECT DISTINCT [CustomerID], [Country], [Region], [Continent]
FROM [SelfLearn].[dbo].[Online_Retail];

UPDATE [SelfLearn].[dbo].[Customers] 
	SET [FirstName] = 'Damir';

UPDATE [SelfLearn].[dbo].[Customers] 
	SET [LastName] = 'Yerlanuly';

UPDATE [SelfLearn].[dbo].[Customers] 
	SET [Phone] = '77778534499';

UPDATE [SelfLearn].[dbo].[Customers] 
	SET [Email] = 'damir_123@gmail.com';

/**** move distinct products description to new Products table from original source ***/
CREATE TABLE [SelfLearn].[dbo].[Products] (
	[ProductID] [int] NOT NULL IDENTITY PRIMARY KEY,
	[ProductFullName] [nvarchar](500) NULL,
	[ProductShortName] [nvarchar](30) NULL,
	[SegmentID] [int] NULL,
	[Price] [float] NOT NULL,
	[StockCode] [nvarchar](50) NULL /*** drop it after joing the ProductID into Order Details table ***/
);

INSERT INTO [SelfLearn].[dbo].[Products] (
			[ProductFullName],
			[Price],
			[StockCode] 
			)
SELECT DISTINCT [Description], [UnitPrice], [StockCode]
FROM [SelfLearn].[dbo].[Online_Retail];

/**** create table ProductSegment table ***/
CREATE TABLE [SelfLearn].[dbo].[ProductSegment](
	[SegmentID] [int] NOT NULL IDENTITY PRIMARY KEY,
	[ProductCategory] [nvarchar](50) NULL
);

/**** create Transaction table from original source ***/
CREATE TABLE [dbo].[Transactions](
	[InvoiceNo] [nvarchar](50) NOT NULL,
	[InvoiceType] [nvarchar](50) NOT NULL,
	[InvoiceDate] [date] NOT NULL,
	[Quantity] [float] NOT NULL,
	[UnitPrice] [float] NOT NULL,
	[CustomerID] [nvarchar](50) NOT NULL,
	[StockCode] [nvarchar](50) NOT NULL,
	[ShippingDate] [date] NOT NULL,
	[ShipDays] [float] NOT NULL
);

INSERT INTO [SelfLearn].[dbo].[Transactions] (
		[InvoiceNo],
		[InvoiceType],
		[InvoiceDate],
		[Quantity],
		[UnitPrice],
		[CustomerID],
		[StockCode],
		[ShippingDate],
		[ShipDays] 
			)
SELECT	[InvoiceNo],
		[InvoiceType],
		[InvoiceDate],
		[Quantity],
		[UnitPrice],
		[CustomerID],
		[StockCode],
		[ShippingDate],
		[ShipDays] 
FROM [SelfLearn].[dbo].[Online_Retail];

--- new attribute StockID creation in Transactions Table ---
ALTER TABLE [SelfLearn].[dbo].[Transactions]
ADD [ProductID] int;

UPDATE [SelfLearn].[dbo].[Transactions] 
	SET [SelfLearn].[dbo].[Transactions].[ProductID] = [SelfLearn].[dbo].[Products].[ProductID]
	FROM [SelfLearn].[dbo].[Transactions] INNER JOIN [SelfLearn].[dbo].[Products] ON [SelfLearn].[dbo].[Transactions].[StockCode] = [SelfLearn].[dbo].[Products].[StockCode] 

--- drop the StockID from Products & Transaction tables as new ID was created ---
ALTER TABLE [SelfLearn].[dbo].[Products]
DROP COLUMN [StockCode];

ALTER TABLE [SelfLearn].[dbo].[Transactions]
DROP COLUMN [StockCode];

-- fill the Product Category after grouping [ProductShortName]
 /**** create Orders table from original source ***/
CREATE TABLE [SelfLearn].[dbo].[Orders] (
	[OrderID] [int] NOT NULL,
	[OrderType] [nvarchar](50) NOT NULL,
	[OrderDate] [date] NULL,
	[ShippingDate] [date] NULL,
	[ShipDays] [float] NULL,
	[CustomerID] [int] NOT NULL
);

INSERT INTO [SelfLearn].[dbo].[Orders] (
	[OrderID],
	[OrderType],
	[OrderDate],
	[ShippingDate],
	[ShipDays],
	[CustomerID]
			)
SELECT	DISTINCT [InvoiceNo],
				 [InvoiceType],
				 [InvoiceDate],
				 [ShippingDate],
				 [ShipDays],
				 [CustomerID]
FROM [SelfLearn].[dbo].[Online_Retail];

/**** create OrderDetails table from original source ***/
CREATE TABLE [SelfLearn].[dbo].[OrdersDetails] (
	[OrderID] [int] NOT NULL,
	[OrderType] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Price] [float] NOT NULL,
	[Discount] [float] NULL
);

INSERT INTO [SelfLearn].[dbo].[OrdersDetails] (
	[OrderID],
	[OrderType],
	[Quantity],
	[Price]
			)
SELECT	DISTINCT [ProductID],
				 [InvoiceType],
				 [Quantity],
				 [UnitPrice]
FROM [SelfLearn].[dbo].[Transactions];

/**** create Dates & move distinct InvoiceDates into new table from original source ***/
CREATE TABLE [SelfLearn].[dbo].[Dates] (
	[InvoiceDate] [date] NOT NULL PRIMARY KEY,
	[Day] [tinyint] NULL,
	[Month] [tinyint] NULL,
	[MonthName] [nvarchar] (15) NULL,
	[Year] [int] NULL,
	[WeekDay] [tinyint] NULL,
	[WeekDayName] [nvarchar] (15) NULL,
	[WeekOfMonth] [tinyint] NULL,
	[WeekOfYear] [int] NULL
);

INSERT INTO [SelfLearn].[dbo].[Dates] (
	[InvoiceDate]
			)
SELECT DISTINCT [InvoiceDate]
FROM [SelfLearn].[dbo].[Online_Retail];

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [Day] = (SELECT DAY([InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 
	
UPDATE [SelfLearn].[dbo].[Dates] 
	SET [Month] = (SELECT MONTH([InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [MonthName] = (SELECT DATENAME(MONTH, [InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [Year] = (SELECT YEAR([InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [WeekDay] = (SELECT DATEPART(WEEKDAY, [InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [WeekDayName] = (SELECT DATENAME(WEEKDAY, [InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [WeekOfMonth] = (SELECT (DATEPART(WEEK, [InvoiceDate]) - DATEPART(WEEK, DATEADD(day, 1, EOMONTH([InvoiceDate], -1)))) + 1)
FROM [SelfLearn].[dbo].[Dates]; 

UPDATE [SelfLearn].[dbo].[Dates] 
	SET [WeekOfYear] = (SELECT DATEPART(WEEK, [InvoiceDate]))
FROM [SelfLearn].[dbo].[Dates]; 

------------------------------------------------  STORED PROCEDURES ------------------------------------------------------
/**** Customer by Country procedure ***/
CREATE PROCEDURE CustomByCountry @Country nvarchar(30)
AS
SELECT * FROM [SelfLearn].[dbo].[Customers] WHERE Country = @Country; 
/** Execute procedure **/
EXEC CustomByCountry @Country = 'Norway';

/**** Customer by Segment & Monetary Spend Value procedure & ***/
CREATE PROCEDURE SegmentSpending
								@Segment nvarchar(30),
								@SpendValue nvarchar(30) = NULL
AS
BEGIN
    SELECT * FROM [SelfLearn].[dbo].[CustomerSegments]
				WHERE (@Segment IS NULL OR @Segment = @Segment) AND (@SpendValue IS NULL OR MonetaryValue = @SpendValue) /*allows to run function by one filter**/
END;

/** Execute procedure **/
EXEC SegmentSpending @Segment = 'Loyal Customers'; 

/**** Each customer classification by spending amount procedure & ***/
CREATE PROCEDURE SpendHabit 
							@Segment nvarchar(30),
							@CustomerID int
AS 
BEGIN
	SELECT [CustomerID], [MonetaryValue], [Segment],
		CASE WHEN [MonetaryValue] BETWEEN 0 AND 500 THEN 'Low Spenders'
		     WHEN [MonetaryValue] BETWEEN 501 AND 5000 THEN 'Moderate Spenders'
		     WHEN [MonetaryValue] BETWEEN 5001 AND 20000 THEN 'Large Spenders'
		     ELSE 'Wholesalers'
		     END AS [CustomerPurchasePower]
	FROM [SelfLearn].[dbo].[CustomersSegments]
			WHERE (@Segment IS NULL OR @Segment = @Segment) AND (@CustomerID IS NULL OR CustomerID = @CustomerID) /*allows to run function by one filter**/
END;
/** Execute procedure **/
EXEC SpendHabit @Segment = 'Loyal Customers', @CustomerID = 12352; 