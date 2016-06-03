USE AdventureWorks2012;
GO
/*
EXEC Sales.CDC_SalesOrderHeader @last_synchronization_version=0
EXEC Sales.CDC_SalesOrderHeader @last_synchronization_version=1
     ,@Incremental_Load = 0
*/

ALTER PROCEDURE Sales.CDC_SalesOrderHeader
(
 @Incremental_Load bit = 1,
 @last_synchronization_version BIGINT
)
AS
--Table variable used in order to force metadata "contract" with SSIS
DECLARE @Data table (
  SalesOrderBK INT
, RevisionNumber TINYINT
, OrderDate DATETIME
, DueDate DATETIME
, ShipDate DATETIME
, Status TINYINT
, OnlineOrderFlag BIT
, SalesOrderNumber NVARCHAR(25)
, PurchaseOrderNumber NVARCHAR(25)
, AccountNumber NVARCHAR(15)
, CustomerBK INT
, SalesPersonBK INT
, TerritoryBK INT
, BillToAddressBK INT
, ShipToAddressBK INT
, ShipMethodBK INT
, CreditCardBK INT
, CreditCardApprovalCode VARCHAR(15)
, CurrencyRateBK INT
, SubTotal MONEY
, TaxAmt MONEY
, Freight MONEY
, TotalDue MONEY
, Comment NVARCHAR(128)
, rowguid UNIQUEIDENTIFIER
, ModifiedDate DATETIME
, SYS_CHANGE_OPERATION VARCHAR(1)
, LSN BIGINT
)

DECLARE @synchronization_version BIGINT
SET @synchronization_version = CHANGE_TRACKING_CURRENT_VERSION();

--Full load
IF (@Incremental_Load = 0 OR @last_synchronization_version=0)
 BEGIN
 Insert into @Data
	SELECT
		SOH.*,
		'I' as SYS_CHANGE_OPERATION,
		0 as Synchronization_version 
	FROM
        Sales.SalesOrderHeader AS SOH
 END
ELSE
 BEGIN
  Insert into @Data
SELECT
/* Obtain incremental changes by using the synchronization version 
	obtained the last time the data was synchronized.*/
    SOH.*,
    CT.SYS_CHANGE_OPERATION,
	@synchronization_version as Synchronization_version 
FROM
    Sales.SalesOrderHeader AS SOH
RIGHT OUTER JOIN
    CHANGETABLE(CHANGES Sales.SalesOrderHeader, @last_synchronization_version) AS CT
ON
    SOH.SalesOrderID = CT.SalesOrderID
 END

--Return the output to SSIS
 Select * from @Data
Return
