-- Taken and adapted from the following link
-- https://stackoverflow.com/questions/3082588/t-sql-function-for-generating-slugs

CREATE FUNCTION [utility].[fnGenerateUrlSlug] ( @toSlugify nvarchar(200) )
RETURNS NVARCHAR(200)
AS
BEGIN
	DECLARE @IncorrectCharLoc SMALLINT
	SET @toSlugify = LOWER(@toSlugify)
	SET @IncorrectCharLoc = PATINDEX('%[^0-9a-z ]%',@toSlugify)
	
	WHILE @IncorrectCharLoc > 0
	BEGIN
		SET @toSlugify = STUFF(@toSlugify,@incorrectCharLoc,1,'')
		SET @IncorrectCharLoc = PATINDEX('%[^0-9a-z ]%',@toSlugify)
	END
	
	SET @toSlugify = REPLACE(@toSlugify,' ','-')
	RETURN @toSlugify
END
