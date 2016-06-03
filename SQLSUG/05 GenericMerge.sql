/*
usp_GenericMerge @SourceSchema = 'etl', @SourceTable='Customers', @TargetSchema='Dim', @TargetTable='Customers'
*/
alter PROCEDURE usp_GenericMerge (
@SourceSchema sysname,
@SourceTable sysname,
@TargetSchema sysname,
@TargetTable sysname,
@Debug bit = 0
)
AS

/*
Merges two table based on the primary key of the Target table

By Rasmus Reinholdt
LinkedIn: dk.linkedin.com/in/rasmusreinholdt/
Twitter: @RasmusReinholdt

8th November 2014                                                              
                                                             
All code samples are provided “AS IS” without warranty of  
any kind, either express or implied, including but not     
limited to the implied warranties of merchantability       
and/or fitness for a particular purpose.

Modelled on http://www.purplefrogsystems.com/download/blog/GenerateMerge.sql
*/

--The variable to hold the dynamic sql is split as the endresult exceeds an nvarchar(max)
DECLARE       @MergeSQL NVARCHAR(MAX)
DECLARE       @UpdateSQL NVARCHAR(MAX)
DECLARE       @InsertSQL NVARCHAR(MAX)

--Create Carriage return variable to help format the resulting query
DECLARE @crlf char(2)
SET @crlf = CHAR(13)
DECLARE @Field varchar(255)
 
--Cursor for primarykey columns
DECLARE myCurPK Cursor FOR
              SELECT  COL_NAME(ic.OBJECT_ID,ic.column_id) AS ColumnName
              FROM    sys.indexes AS i INNER JOIN
                           sys.index_columns AS ic ON  i.OBJECT_ID = ic.OBJECT_ID
                                                                     AND i.index_id = ic.index_id
              WHERE   i.is_primary_key = 1
              AND OBJECT_NAME(i.OBJECT_ID) = @TargetTable 

--Cursor for columns to be updated (all columns except the primary key columns)
DECLARE myCurUpdate CURSOR FOR
     SELECT c.name
        FROM sys.columns c
                     INNER JOIN sys.indexes i ON i.object_id = c.object_id
        WHERE OBJECT_NAME(c.OBJECT_ID) = @TargetTable
       GROUP BY c.name
          HAVING MIN(CAST(i.is_primary_key AS INT)) = 0
 

--Cursor for all columns, used for insert
DECLARE myCurALL CURSOR FOR
     SELECT c.name
        FROM sys.columns c
        WHERE OBJECT_NAME(c.OBJECT_ID) = @TargetTable
 
--Building the DynamicSQL
SET @MergeSQL = '
MERGE ' + @TargetSchema + '.' + @TargetTable + ' AS Target
     USING ' + @SourceSchema +'.'+ @SourceTable + ' AS Source
         ON '	
 OPEN myCurPK
    FETCH NEXT FROM myCurPK INTO @Field
    IF (@@FETCH_STATUS>=0)
        BEGIN
            SET @MergeSQL = @MergeSQL + @crlf + '           SOURCE.' + @Field + ' = TARGET.'  + @Field
            FETCH NEXT FROM myCurPK INTO @Field
        END
    WHILE (@@FETCH_STATUS<>-1)
    BEGIN
        IF (@@FETCH_STATUS<>-2)
            SET @MergeSQL = @MergeSQL + @crlf + '           ,' + @Field + ' = TARGET.'  + @Field
        FETCH NEXT FROM myCurPK INTO @Field
    END
  CLOSE myCurPK

SET @UpdateSQL =  'WHEN MATCHED
       THEN UPDATE SET'
  OPEN myCurUpdate
    FETCH NEXT FROM myCurUpdate INTO @Field
    IF (@@FETCH_STATUS>=0)
        BEGIN
            SET @UpdateSQL = @UpdateSQL + @crlf + '           ' + @Field + ' = SOURCE.'  + @Field
            FETCH NEXT FROM myCurUpdate INTO @Field
        END
    WHILE (@@FETCH_STATUS<>-1)
    BEGIN
        IF (@@FETCH_STATUS<>-2)
            SET @UpdateSQL = @UpdateSQL + @crlf + '           ,' + @Field + ' = SOURCE.'  + @Field
        FETCH NEXT FROM myCurUpdate INTO @Field
    END
  CLOSE myCurUpdate

SET @InsertSQL =  @crlf +
    'WHEN NOT MATCHED THEN
       INSERT (
        '
  OPEN myCurALL
    FETCH NEXT FROM myCurALL INTO @Field
    IF (@@FETCH_STATUS>=0)
        BEGIN
            SET @InsertSQL = @InsertSQL + @crlf + '           ' + @Field
            FETCH NEXT FROM myCurALL INTO @Field
        END
    WHILE (@@FETCH_STATUS<>-1)
    BEGIN
        IF (@@FETCH_STATUS<>-2)
            SET @InsertSQL = @InsertSQL + @crlf + '           ,' + @Field
        FETCH NEXT FROM myCurALL INTO @Field
    END
  CLOSE myCurALL

SET @InsertSQL =  @InsertSQL + @crlf + '
     )'
 
SET @InsertSQL =  @InsertSQL + @crlf +
  'VALUES ('
  OPEN myCurALL
    FETCH NEXT FROM myCurALL INTO @Field
    IF (@@FETCH_STATUS>=0)
        BEGIN
            SET @InsertSQL = @InsertSQL + @crlf + '           SOURCE.' + @Field
            FETCH NEXT FROM myCurALL INTO @Field
        END
    WHILE (@@FETCH_STATUS<>-1)
    BEGIN
        IF (@@FETCH_STATUS<>-2)
            SET @InsertSQL = @InsertSQL + @crlf + '           , SOURCE.' + @Field
        FETCH NEXT FROM myCurALL INTO @Field
    END
  CLOSE myCurALL
SET @InsertSQL =  @InsertSQL + @crlf +
'      )
;'

 --clean up
    DEALLOCATE myCurUpdate
    DEALLOCATE myCurAll
    DEALLOCATE myCurPK 

 IF @Debug = 0
    BEGIN
        EXEC(@MergeSQL + @UpdateSQL + @InsertSQL)          
    END
   ELSE
    BEGIN   
              PRINT @MergeSQL
              PRINT @UpdateSQL
              PRINT @InsertSQL
    END