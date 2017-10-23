CREATE PROCEDURE [utility].[spPrintSkeletonScriptCreateTable]
    @schemaName nvarchar(50),
    @tableName nvarchar(50),
	@includeRowIndex bit = 0
AS
BEGIN
	--DECLARE
	--	@schemaName nvarchar(50) = 'authoring',
	--	@tableName nvarchar(50) = 'AuthoredContentStatus';
	DECLARE
		@SQL nvarchar(MAX);

	SET @SQL = 
'CREATE TABLE [' + @schemaName + '].[' + @tableName + '] (';
	IF @includeRowIndex = 0
	BEGIN
		SET @SQL = @SQL + '
	[Identity] uniqueidentifier NOT NULL DEFAULT NewId() PRIMARY KEY CLUSTERED,'
	END
	ELSE
	BEGIN
		SET @SQL = @SQL + '
	[Identity] uniqueidentifier NOT NULL DEFAULT NewId() PRIMARY KEY NONCLUSTERED, [RowIndex] int NOT NULL Identity(1, 1),'
	END

	SET @SQL = @SQL + '
	-- Your fields go here
	
);
GO'

IF @includeRowIndex = 1
BEGIN
	SET @SQL = @SQL + '

CREATE CLUSTERED INDEX IX_' + @tableName + '_RowIndex ON [' + @schemaName +'].[' + @tableName + ']([RowIndex]);
GO'
END

	PRINT @SQL;
END
GO