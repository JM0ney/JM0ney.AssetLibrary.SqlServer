--
--	Do you like this project? Do you find it helpful? Pay it forward by hiring me as a consultant!
--  https://jason-iverson.com
--
CREATE PROCEDURE [utility].[spPrintCSharpClassDefinition]
	@SchemaName nvarchar(max), 
	@TableName nvarchar(max)
AS
BEGIN

SET NOCOUNT ON;

--DECLARE
--	@schemaName nvarchar(max) = 'dbo', 
--	@tableName nvarchar(max) = 'Prospects'


DECLARE @VariableMapping TABLE (
	SqlDataType nvarchar(100),
	CSharpDataType nvarchar(100),
	CSharpDataTypeNullable nvarchar(100),
	CSharpDefaultValue nvarchar(50),
	CSharpNullableDefaultValue nvarchar(50) DEFAULT 'null'
);


INSERT INTO @VariableMapping (SqlDataType, CSharpDataType, CSharpDataTypeNullable, CSharpDefaultValue, CSharpNullableDefaultValue)
SELECT 'bigint', 'long', 'long?', '0', 'null' UNION
SELECT 'bit', 'Boolean', 'Boolean?', 'false', 'null' UNION
SELECT 'char', 'String', 'String', 'String.Empty', 'String.Empty' UNION
SELECT 'date', 'DateTime', 'DateTime?', 'DateTime.Now', 'null' UNION
SELECT 'datetime', 'DateTime', 'DateTime?', 'DateTime.Now', 'null' UNION
SELECT 'decimal', 'decimal', 'decimal?', '0', 'null' UNION
SELECT 'float', 'float', 'float?', '0f', 'null' UNION
SELECT 'int', 'int', 'int?', '0', 'null' UNION
SELECT 'money', 'decimal', 'decimal?', '0', 'null' UNION
SELECT 'nchar', 'String', 'String', 'String.Empty', 'String.Empty' UNION
SELECT 'ntext', 'String', 'String', 'String.Empty', 'String.Empty' UNION
SELECT 'numeric', 'decimal', 'decimal?', '0', 'null' UNION
SELECT 'nvarchar', 'String', 'String', 'String.Empty', 'String.Empty' UNION
SELECT 'real', 'double', 'double?', '0.0', 'null' UNION
SELECT 'smalldatetime', 'DateTime', 'DateTime?', 'DateTime.Now', 'null' UNION
SELECT 'smallint', 'short', 'short?', '0', 'null' UNION
SELECT 'smallmoney', 'decimal', 'decimal?', '0', 'null' UNION
SELECT 'text', 'String', 'String', 'String.Empty', 'String.Empty' UNION
SELECT 'time', 'TimeSpan', 'TimeSpan?', 'TimeSpan.MinValue', 'null' UNION
SELECT 'tinyint', 'byte', 'byte?', '0', 'null' UNION
SELECT 'uniqueidentifier', 'Guid', 'Guid?', 'Guid.Empty', 'null' UNION
SELECT 'varchar', 'String', 'String', 'String.Empty', 'String.Empty' 


DECLARE @ClassFields TABLE (
	[FieldName] nvarchar(100) NOT NULL PRIMARY KEY,
	[CSharpDataType] nvarchar(100) NOT NULL,
	[CSharpDefaultValue] nvarchar(100) NOT NULL
);

INSERT INTO @ClassFields (FieldName, CSharpDataType, CSharpDefaultValue)
SELECT
	COLUMN_NAME AS FieldName,
	(SELECT Case When IS_NULLABLE = 'YES' Then CSharpDataTypeNullable Else CSharpDataType End FROM @VariableMapping WHERE SqlDataType = C.DATA_TYPE) AS CSharpDataType,
	(SELECT Case When IS_NULLABLE = 'YES' Then CSharpNullableDefaultValue Else  CSharpDefaultValue  End FROM @VariableMapping WHERE SqlDataType = C.DATA_TYPE) AS CSharpDefaultValue
FROM
	INFORMATION_SCHEMA.COLUMNS AS C
WHERE
	C.[TABLE_NAME] = @tableName
AND
	C.[TABLE_SCHEMA] = @schemaName
ORDER BY
	C.ORDINAL_POSITION;


SELECT
	*
INTO 
	#Fields
FROM 
	@ClassFields


SELECT
	*
INTO 
	#Properties
FROM 
	@ClassFields

DECLARE
	@FieldName nvarchar(100),
	@DataType nvarchar(100),
	@DefaultValue nvarchar(100);

PRINT 'public class ' + @TableName + ' {'


PRINT '
    #region Fields

'

WHILE (SELECT COUNT(*) FROM #Fields) > 0
BEGIN
	SELECT TOP 1 
		@FieldName = FieldName,
		@DataType = CSharpDataType,
		@DefaultValue = CSharpDefaultValue
	FROM
		#Fields

	PRINT '    private ' + @DataType + ' _' + @FieldName + ' = ' + @DefaultValue + ';';

	DELETE FROM #Fields WHERE [FieldName] = @FieldName;
END

PRINT '
    #endregion Fields

	#region Constructor(s)

	public ' + @TableName + '( ) {
	}
	
	#endregion Constructor(s)
	
	#region Properties '

WHILE (SELECT COUNT(*) FROM #Properties) > 0
BEGIN
	SELECT TOP 1 
		@FieldName = FieldName,
		@DataType = CSharpDataType,
		@DefaultValue = CSharpDefaultValue
	FROM
		#Properties

	PRINT '
	public ' + @DataType + ' ' + @FieldName + ' {
		get { return this._' + @FieldName + '; }
		set { this._' + @FieldName + ' = value; }
	}'
		

	DELETE FROM #Properties WHERE [FieldName] = @FieldName;
END

PRINT '
    #endregion Properties
'

PRINT '}'


DROP TABLE #Fields
DROP TABLE #Properties

END
