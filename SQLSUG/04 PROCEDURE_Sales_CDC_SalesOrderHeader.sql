/*
EXEC Sales.CDC_SalesOrderHeader @last_synchronization_version=1
*/

CREATE PROCEDURE Sales.CDC_SalesOrderHeader
(
 @last_synchronization_version BIGINT
)
AS
DECLARE @synchronization_version BIGINT
SET @synchronization_version = CHANGE_TRACKING_CURRENT_VERSION();

-- Obtain incremental changes by using the synchronization version obtained the last time the data was synchronized.

SELECT
    SOH.*,
    CT.SYS_CHANGE_OPERATION,
	@synchronization_version as Synchronization_version 
FROM
    Sales.SalesOrderHeader AS SOH
RIGHT OUTER JOIN
    CHANGETABLE(CHANGES Sales.SalesOrderHeader, @last_synchronization_version) AS CT
ON
    SOH.SalesOrderID = CT.SalesOrderID

