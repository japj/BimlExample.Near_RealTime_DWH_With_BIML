USE AdventureWorks2012;
GO
/*
EXEC Sales.CDC_SalesOrderDetail @last_synchronization_version=0
EXEC Sales.CDC_SalesOrderDetail @last_synchronization_version=250 
      ,@Incremental_Load = 1
*/

ALTER PROCEDURE Sales.CDC_SalesOrderDetail
(
 @Incremental_Load bit = 1,
 @last_synchronization_version BIGINT
)
AS
--Table variable used in order to force metadata "contract" with SSIS
DECLARE @Data table (
  SalesOrderBK INT
, SalesOrderDetailBK INT
, CarrierTrackingNumber NVARCHAR(25)
, OrderQty SMALLINT
, ProductBK INT
, SpecialOfferBK INT
, UnitPrice MONEY
, UnitPriceDiscount MONEY
, LineTotal NUMERIC(38,6)
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
   INSERT INTO @Data
	SELECT
		SOd.*,
		'I' as SYS_CHANGE_OPERATION,
		0 as Synchronization_version 
	FROM
        Sales.SalesOrderDetail AS SOd
 END
ELSE
 BEGIN
/* Obtain incremental changes by using the synchronization version 
   obtained the last time the data was synchronized.*/
   INSERT INTO @Data
	SELECT
		SOD.*,
		CT.SYS_CHANGE_OPERATION,
		@synchronization_version as Synchronization_version 
	FROM
		Sales.SalesOrderDetail AS SOD
	RIGHT OUTER JOIN
	  CHANGETABLE(CHANGES Sales.SalesOrderDetail, @last_synchronization_version) AS CT
	ON
		SOD.SalesOrderID = CT.SalesOrderID
		AND SOD.SalesOrderDetailID = CT.SalesOrderDetailID
END

--Return the output to SSIS
 Select * from @Data
Return
