CREATE PROCEDURE [utility].[spPrintSkeletonScriptCRUDProcedures]
    @schemaName nvarchar(50),
    @nameSingular nvarchar(50),
    @namePlural nvarchar(50)
AS
BEGIN

    SET NOCOUNT ON;

        /*
        DECLARE
            @schemaName nvarchar(20),
            @nameSingular nvarchar(50),
            @namePlural nvarchar(50),
            @procLoad varchar(max),
            @procSave varchar(max),
            @procDelete varchar(max),
            @procList varchar(max);

        SELECT
            @nameSingular = 'Unit',
            @namePlural = 'Units',
            @schemaName = 'dbo';
        */
        DECLARE
			@procFileNames varchar(max),
            @procLoad varchar(max),
            @procSave varchar(max),
            @procDelete varchar(max),
            @procList varchar(max),
            @procListBy varchar(max);

        DECLARE @ExcludedFields TABLE (
            FieldName nvarchar(40) NOT NULL
        );

        DECLARE @IncludedFields TABLE (
            FieldName nvarchar(40) NOT NULL,
            ColumnId int
        );

        DECLARE @PossibleOrderFields TABLE (
            FieldName nvarchar(40) NOT NULL
        );

        INSERT INTO @ExcludedFields 
        SELECT 'RowIndex' UNION
        SELECT 'OldId'

        INSERT INTO @PossibleOrderFields
        SELECT 'Number' UNION
        SELECT 'SortOrder'

        DECLARE
            @objectId bigint,
            @isView bit = 0,
            @columnsCSL varchar(max),
            @updateSetColumnsCSL varchar(max),
            @paramsCSL varchar(max),
            @paramsTypedCSL varchar(max),
            @orderByClause varchar(100);
            --@procLoad varchar(max),
            --@procSave varchar(max),
            --@procDelete varchar(max),
            --@procList varchar(max);

        SELECT 
            @objectId = object_id
        FROM 
            sys.tables
        WHERE 
            [Name] = @nameSingular;

        IF @objectId IS NULL 
        BEGIN
            SET @isView = 1;
            SELECT 
                @objectId = object_id
            FROM 
                sys.views
            WHERE 
                [Name] = @nameSingular;
        END



        INSERT INTO @IncludedFields (FieldName, ColumnId)
        SELECT 
            [name],
            column_id
        FROM 
            sys.columns
        WHERE
            object_id = @objectId
        AND
            [Name] NOT IN (SELECT * FROM @ExcludedFields)
        ORDER BY
            column_id

    
        SELECT
            @columnsCSL = ISNULL(@columnsCSL, '') + '[' + [FieldName] + '], ',
            @paramsCSL =  ISNULL(@paramsCSL, '') + '@' + [FieldName] + ', ',
            @paramsTypedCSL = ISNULL(@paramsTypedCSL, '') + '@' + [FieldName] + ' ' + sys.types.name + Case When sys.types.name = 'nvarchar' Then '(' + Case When (sys.columns.max_length / 2) = 0 THEN 'max' Else Cast((sys.columns.max_length / 2) as varchar(10)) End + ')' Else '' End + ', ',
            @updateSetColumnsCSL = ISNULL(@updateSetColumnsCSL, '') +
                Case When [FieldName] = 'Identity' Then '' Else '[' + [FieldName] + ']'  + ' = @' + [FieldName] + ', ' End ,
            @orderByClause = ISNULL(@orderByClause, '') +
                Case When EXISTS (SELECT * FROM @PossibleOrderFields WHERE FieldName = sys.columns.name) Then '[' + [FieldName] + '], ' Else '' End
        FROM
            @IncludedFields F
        INNER JOIN sys.columns ON
            sys.columns.column_id = F.ColumnId 
            AND sys.columns.name = F.FieldName
            AND sys.columns.object_id = @objectId
        INNER JOIN sys.types ON
            sys.columns.user_type_id = sys.types.user_type_id
            AND sys.types.name <> 'sysname'


        SET @columnsCSL = SUBSTRING(RTRIM(@columnsCSL), 1, LEN(RTRIM(@columnsCSL)) - 1)
        SET @paramsCSL = SUBSTRING(RTRIM(@paramsCSL), 1, LEN(RTRIM(@paramsCSL)) - 1)
        SET @paramsTypedCSL = SUBSTRING(RTRIM(@paramsTypedCSL), 1, LEN(RTRIM(@paramsTypedCSL)) - 1)

        IF CHARINDEX(',', @updateSetColumnsCSL) >= 1
        BEGIN
            SET @updateSetColumnsCSL = SUBSTRING(RTRIM(@updateSetColumnsCSL), 1, LEN(RTRIM(@updateSetColumnsCSL)) - 1);
        END

        IF CHARINDEX(',', @orderByClause) >= 1
        BEGIN
            SET @orderByClause = 'ORDER BY ' + SUBSTRING(RTRIM(@orderByClause), 1, LEN(RTRIM(@orderByClause)) - 1);
        END

		SET @procFileNames = '';
		
        SELECT
            @procList = 'CREATE PROCEDURE [' + @schemaName + '].[sp' + @namePlural + 'List]
AS
BEGIN
    SELECT ' + @columnsCSL + ' FROM 
    [' + @schemaName + '].[' + @nameSingular + '] 
    ' + @orderByClause + ';
END
GO

'



    SELECT
        @procDelete ='CREATE PROCEDURE [' + @schemaName + '].[sp' + @nameSingular + 'Delete] (
    @Identity uniqueidentifier
)
AS
BEGIN
    DELETE FROM [' + @schemaName + '].[' + @nameSingular + '] WHERE [Identity] = @Identity;
END
GO

'


    SELECT
        @procSave = 'CREATE PROCEDURE [' + @schemaName + '].[sp' + @nameSingular + 'Save] (
    ' + @paramsTypedCSL + '
)
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM [' + @schemaName + '].[' + @nameSingular + '] WHERE [Identity] = @Identity)
    BEGIN
        INSERT INTO  [' + @schemaName + '].[' + @nameSingular + '] (' + @columnsCSL + ')
        VALUES (' + @paramsCSL + ');
    END
    ELSE
    BEGIN
        UPDATE [' + @schemaName + '].[' + @nameSingular + ']
        SET ' + @updateSetColumnsCSL + '
        WHERE [Identity] = @Identity
    END
END
GO
    
';
    


        SELECT
            @procLoad = 'CREATE PROCEDURE [' + @schemaName + '].[sp' + @nameSingular + 'Load](
    @Identity uniqueidentifier
)
AS
BEGIN
    SELECT ' + @columnsCSL + ' 
    FROM [' + @schemaName + '].[' + @nameSingular + '] 
    WHERE [Identity] = @Identity;
END
GO

';



    DECLARE @FKTableMaps TABLE (
        TableId bigint,
        ReferenceTableId bigint
    )


    INSERT INTO @FKTableMaps
    SELECT 
        parent_object_id,
        referenced_object_id 
    FROM sys.foreign_keys
    WHERE
        parent_object_id = object_id( @schemaName + '.' + @nameSingular)




    DECLARE
        @fkColumnName varchar(50)

    -- Will need to tweak this if there are FK types other than uniqueidentifier
    -- or there is ever a composite foreign key made up of 2+ fields
    DECLARE CUR CURSOR FOR
    SELECT 
        --m.TableId,
        --m.ReferenceTableId,
        col1.Name as ForeignKeyColumnName
    FROM sys.foreign_key_columns as fk
    inner join @FKTableMaps AS m
        ON m.TableId = fk.parent_object_id
        AND m.ReferenceTableId = fk.referenced_object_id
    inner join sys.columns AS col1
        ON col1.object_id = fk.parent_object_id
        and col1.column_id = fk.parent_column_id
    WHERE
        col1.Name <> 'Identity'

    OPEN CUR
    FETCH NEXT FROM CUR INTO @fkColumnName

	SET @procFileNames += 'sp' + @nameSingular + 'Load 
' + @procFileNames + 'sp' + @nameSingular + 'Save 
' + @procFileNames + 'sp' + @nameSingular + 'Delete 
' + @procFileNames + 'sp' + @namePlural + 'List 
'


    WHILE @@FETCH_STATUS = 0
    BEGIN

	SET @procFileNames += 'sp' + @namePlural + 'ListBy' + @fkColumnName + '
'
    
        SELECT
            @procListBy = ISNULL(@procListBy, '') + 
'
CREATE PROCEDURE [' + @schemaName + '].[sp' + @namePlural + 'ListBy' + @fkColumnName + '](
    @' + @fkColumnName + ' uniqueidentifier
)
AS
BEGIN
    SELECT ' + @columnsCSL + ' FROM [' + @schemaName + '].[' + @nameSingular + ']
    WHERE [' + @fkColumnName + '] = @' + @fkColumnName + ' ' + @orderByClause + ';
END
GO

'

        FETCH NEXT FROM CUR INTO @fkColumnName    
    END

    CLOSE CUR
    DEALLOCATE CUR

	SET @procFileNames += '
	'

	PRINT @procFileNames 

    PRINT @procLoad

    PRINT @procSave

    PRINT @procDelete

    PRINT @procList

    PRINT @procListBy


END
GO