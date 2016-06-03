use AdventureWorksStaging2012;
GO
/*
 usp_GenericMerge @SourceSchema = 'etl', @SourceTable='Customer'
	, @TargetSchema='Dim', @TargetTable='Customer', @debug=1
 */
 CREATE PROCEDURE usp_GenericMerge (
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

 All code samples are provided “AS IS” without warranty of
 any kind, either express or implied, including but not
 limited to the implied warranties of merchantability
 and/or fitness for a particular purpose.
 Modeled on http://www.purplefrogsystems.com/download/blog/GenerateMerge.sql
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
 SELECT c.name
 FROM sys.columns c
 INNER JOIN sys.indexes i 
  ON c.object_id = i.object_id
 INNER JOIN sys.index_columns IC 
  ON IC.column_id = c.column_id
  AND IC.object_id = c.object_id
  AND i.index_id = IC.index_id
 WHERE OBJECT_NAME(c.OBJECT_ID) = @TargetTable
  AND i.is_primary_key = 1

--Cursor for columns to be updated (all columns except the primary key columns)
 DECLARE myCurUpdate CURSOR FOR
 SELECT c.name
 FROM sys.columns c
 left JOIN sys.index_columns IC 
  ON IC.column_id = c.column_id
  AND IC.object_id = c.object_id
  AND IC.column_id = c.column_id
 left JOIN sys.indexes i ON i.object_id = ic.object_id
  AND i.index_id = IC.index_id
 WHERE OBJECT_NAME(c.OBJECT_ID) = @TargetTable
  AND ISNULL(i.is_primary_key,0) = 0 

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
 SET @MergeSQL = @MergeSQL + @crlf + '           AND SOURCE.' + @Field + ' = TARGET.'  + @Field
 FETCH NEXT FROM myCurPK INTO @Field
 END
 CLOSE myCurPK

SET @UpdateSQL =  'WHEN MATCHED ' + @crlf + '
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