USE [AdventureWorksDataMart2012]
GO

/****** Object:  StoredProcedure [dbo].[Proc_AddEarlyArrivingFacts_SalesTerritory]    Script Date: 11-12-2014 22:39:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*Procedure to create SKs for early arriving facts, consept develop by
Thomas Kejser, SQLCAT
*/
CREATE PROCEDURE [dbo].[Proc_AddEarlyArrivingFacts_SalesTerritory]
  @LookupKey INT /* The key to find a surrogate for */ 
AS 
SET NOCOUNT ON

/* Prevent race conditions */ 
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

/* Check if we already have the key (procedure is idempotent) */ 
DECLARE @SalesTerritory_ID BIGINT 
SELECT @SalesTerritory_ID = SalesTerritory_ID 
FROM Dim.SalesTerritory A
WHERE SalesTerritoryBK = @LookupKey

/* The natural key was not found, generate a new one and expire the old one if it is older than the one we insert*/ 
IF @SalesTerritory_ID IS NULL BEGIN 

  INSERT Dim.SalesTerritory(SalesTerritoryBK) VALUES (@LookupKey) 
  SET @SalesTerritory_ID = SCOPE_IDENTITY() 
END



/* Return the result.  
  IMPORTANT: must return same format as the SELECT statement we replaced */ 
SELECT @SalesTerritory_ID AS SalesTerritory_ID, @LookupKey AS LookupKey




GO


