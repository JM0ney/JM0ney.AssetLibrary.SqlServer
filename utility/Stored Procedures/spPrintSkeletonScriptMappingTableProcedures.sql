--
--	Do you like this project? Do you find it helpful? Pay it forward by hiring me as a consultant!
--  https://jason-iverson.com
--
CREATE PROCEDURE [utility].[spPrintSkeletonScriptMappingTableProcedures]
    @schemaName nvarchar(50),
	@mappingTableName nvarchar(50)
AS
BEGIN
    DECLARE 
        @script nvarchar(max),
		@schemaId int,
		@tableId int,
		@parameters nvarchar(1000),
		@procName nvarchar(200),
		@objectName nvarchar(200),
		@whereClause nvarchar(500),
		@paramsCSL nvarchar(200),
		@colsCSL nvarchar(200);

	SELECT 
		@parameters = '', @whereClause = '', @paramsCSL = '', @colsCSL = '',
		@procName = '[' + @schemaName + '].[sp' + @mappingTableName + 'AssertMapping]',
		@objectName = '[' + @schemaName + '].[' + @mappingTableName + ']';
	DECLARE @ExcludedColumns TABLE (
		[Name] nvarchar(30) NOT NULL
	);

	DECLARE @Columns TABLE (
		[Name] nvarchar(30) NOT NULL,
        [ColumnId] int
	);

	INSERT INTO @ExcludedColumns
	SELECT 'RowIndex';

	SELECT @schemaId = [schema_id] FROM sys.schemas WHERE name = @schemaName;
	SELECT @tableId = [object_id] from sys.tables where name = @mappingTableName and [schema_id] = @schemaId;

	insert into @Columns
	select name, column_id from sys.columns 
	where object_id = @tableId
	and [name] not in (select * from @ExcludedColumns);

	SELECT
		@parameters = @parameters + '@'+ F.[Name] + ' ' + sys.types.name + Case When sys.types.name = 'nvarchar' Then '(' + Case When (sys.columns.max_length / 2) = 0 THEN 'max' Else Cast((sys.columns.max_length / 2) as varchar(10)) End + ')' Else '' End + ', ',
		@paramsCSL = @paramsCSL + '@' + F.[Name] + ', ',
		@colsCSL = @colsCSL + '[' + F.[Name] + '], '
	FROM
		@Columns AS F
    INNER JOIN sys.columns ON
        sys.columns.column_id = F.ColumnId 
        AND sys.columns.name = F.Name
        AND sys.columns.object_id = @tableId
    INNER JOIN sys.types ON
        sys.columns.user_type_id = sys.types.user_type_id
        AND sys.types.name <> 'sysname'

	SELECT
		@whereClause = @whereClause + '[' + [Name] + '] = @' + [Name] + ' AND '
	FROM
		@Columns
	WHERE
		[Name] NOT IN ('SortOrder')

	IF LEN(@parameters) > 2
	BEGIN
		SELECT 
			@parameters = @parameters + '@ensureExists bit',
			@whereClause = ' WHERE ' + SUBSTRING(@whereClause, 1, LEN(@whereClause) - 3),
			@paramsCSL = SUBSTRING(@paramsCSL, 1, LEN(@paramsCSL) - 1),
			@colsCSL = SUBSTRING(@colsCSL, 1, LEN(@colsCSL) - 1)
	END
	
	SET @script = 'CREATE PROCEDURE ' + @procName + ' (
	' + @parameters + '
)
AS
BEGIN

	IF @ensureExists = 1
	BEGIN
		EXEC ' + @procName + ' ' + @paramsCSL + ', 0;

		IF NOT EXISTS (SELECT * FROM ' + @objectName +  @whereClause + ')
		BEGIN
			INSERT INTO ' + @objectName + ' ( ' + @colsCSL + ' )
			VALUES ( ' + @paramsCSL + ' );
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT * FROM ' + @objectName +  @whereClause + ')
		BEGIN
			DELETE FROM ' + @objectName + RTRIM( @whereClause ) + ';
		END
	END

END
GO '

	print @script
END
GO