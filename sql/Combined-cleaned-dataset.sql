-- Checking rows counts after import

Select Count(*) As Rows_2009_2010 From dbo.[Year 2009-2010];
Select Count(*) As Rows_2010_2011 From dbo.[Year 2010-2011];



-- Combining both years and converting types

Select 
     Invoice, StockCode, Description, Quantity,
     
     Coalesce(
     Try_Convert(datetime2, InvoiceDate, 120),
     Try_Convert(datetime2, InvoiceDate, 105)
     ) As InvoiceDate,

     Try_Convert(decimal(10,2), Price) As Price,
     Customer_ID, Country, '2009-2010' As SourceSheet
Into dbo.RetailCombined
From dbo.[Year 2009-2010]

Union All

Select 
     Invoice, StockCode, Description, Quantity,
     
     Coalesce(
     Try_Convert(datetime2, InvoiceDate, 120),
     Try_Convert(datetime2, InvoiceDate, 105)
     ) As InvoiceDate,

     Try_Convert(decimal(10,2), Price) As Price,
     Customer_ID, Country, '2010-2011' As SourceSheet
From dbo.[Year 2010-2011];



-- Confirming conversion is working cleanly

Select Count(*) AS Total_Rows From dbo.RetailCombined;
Select Count(*) AS Failed_Dates From dbo.RetailCombined Where InvoiceDate Is Null;
Select Count(*) AS Failed_Prices From dbo.RetailCombined Where Price Is Null;


-- checking missing values

Select count(*) As Missing_Valuse
From dbo.RetailCombined 
Where Customer_ID Is Null;

Select count(*) As negative_Qty
From dbo.RetailCombined
Where Quantity <= 0;

Select count(*) As Missing_Description
From dbo.RetailCombined
Where Description Is Null;


-- checking exact duplicate rows
Select Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_Id, Country,
       Count(*) As ExactDupeCount
From dbo.RetailCombined
Group By Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_Id, Country
Having Count(*) > 1;


-- Producing final cleaned table
With Deduped As (
     Select *,
         Row_Number() Over (
            Partition By Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_Id, Country
            Order By (Select Null)
         ) As RowNum
     From dbo.RetailCombined 
)
Select Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_Id, Country, SourceSheet
Into dbo.RetialCleaned
From Deduped
Where RowNum = 1;

Select * From dbo.RetialCleaned;