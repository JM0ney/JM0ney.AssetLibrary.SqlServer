--
--	Do you like this project? Do you find it helpful? Pay it forward by hiring me as a consultant!
--  https://jason-iverson.com
--
CREATE PROCEDURE [utility].[spPrintSkeletonScriptUpgradeScript]
AS
BEGIN
DECLARE @stamp nvarchar(50) = Cast(newid() as nvarchar(50))

PRINT 'SET NOCOUNT ON;
DECLARE 
    @updateStamp UNIQUEIDENTIFIER,
    @error int, @lineNumber int,
    @msg nvarchar(max)
SELECT @error = 0, @lineNumber = 0, @msg = '''', @updateStamp = ''' + @stamp + ''';

IF NOT EXISTS (SELECT * FROM maintenance.SchemaUpdates WHERE [Identity] = @updateStamp)
BEGIN
    BEGIN TRANSACTION TRANSx;
    BEGIN TRY
        -- Your script(s) here...
        

        -- Log the execution of this SchemaUpdate
        INSERT INTO maintenance.SchemaUpdates ([Identity]) VALUES (@updateStamp);
        SELECT @error = @@ERROR;
    END TRY
    BEGIN CATCH
        -- Gather error details
        SELECT @error = @@ERROR;
        SELECT @msg = ERROR_MESSAGE();
        SELECT @lineNumber = ERROR_LINE();
    END CATCH
    
    IF @error = 0
    BEGIN
        COMMIT TRANSACTION TRANSx;
    END
    ELSE
    BEGIN
        PRINT ''================================================================================================================================================''
        PRINT ''SCRIPT ERROR''
        PRINT ''================================================================================================================================================''
        PRINT ''Error number:  '' + Cast(@error as nvarchar(10)) 
        PRINT ''Line number:   '' + Cast(@lineNumber as nvarchar(10)) 
        PRINT ''Error message: '' + @msg 
        PRINT ''================================================================================================================================================''
        ROLLBACK TRANSACTION TRANSx;
    END
END
ELSE
BEGIN
    DECLARE @when DATETIME;
    SELECT @when = ExecutionTimestamp FROM maintenance.[SchemaUpdates] WHERE [Identity] = @updateStamp
    PRINT ''The update that corresponds to '' + Convert(varchar(40), @updateStamp) + '' has previously been applied on '' + Convert(varchar(40), @when, 109)
END'
END
GO