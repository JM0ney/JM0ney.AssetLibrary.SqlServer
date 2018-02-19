CREATE PROCEDURE [maintenance].[spEnsureRolePermissions]
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ExecScripts TABLE (
		Id int Identity(1, 1),
		Script nvarchar(max)
	);

	INSERT INTO @ExecScripts (Script)
	SELECT 
		'GRANT EXECUTE ON [' + S.name + '].[' + p.name + '] TO [public]'
	FROM sys.procedures AS P
	INNER JOIN sys.schemas as S
		ON p.schema_id = S.schema_id
	WHERE S.schema_id in (
		SELECT schema_id FROM sys.schemas
		WHERE
			[Name] IN ('dbo')

	)
	ORDER BY
		1


	DECLARE @Id int, @Script nvarchar(max);
	WHILE (SELECT COUNT(*) FROM @ExecScripts) > 0
	BEGIN
		SELECT TOP 1 @Id = Id FROM @ExecScripts;
		SELECT @Script = Script FROM @ExecScripts WHERE Id = @Id;

		DELETE FROM @ExecScripts WHERE Id = @Id;
		EXEC(@Script);
	END
END