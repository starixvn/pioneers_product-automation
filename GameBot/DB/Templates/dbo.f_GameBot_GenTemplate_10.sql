CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_10
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot',
    @Sporttype INT = 0,
    @Bettype INT = 0,
    @ProductType VARCHAR(20) = 'RNG'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @ServerAlias VARCHAR(100) = N'DBTXN',
            @DBName VARCHAR(100) = N'bodb02'
            ;
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Scr01_{date}_{RedmineID}_{ProductName}_WinlimitProductOffer.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBTXN-bodb02"></info>*/
        /*
                Created: {Nickname}@{date}
                Task: {ProductName} - Integrate new product - Implement Setting and Initial data [RedmineID: #{RedmineID}]
                DB: DBTXN-bodb02
        */

        USE bodb02
        GO

        DECLARE @ProductType VARCHAR(20) = ''{ProductType}'',
                        @ProductID    TINYINT = {ProductId},
                        @Bettype        SMALLINT

        SET @Bettype = CASE WHEN @ProductType=''RNG'' THEN 4001 ELSE {Bettype} END


        IF EXISTS (
                SELECT TOP 1 1
                FROM WinLimit_ProductOffer WITH (NOLOCK)
                WHERE ProductID = @ProductID AND BetType = @Bettype
        )
        BEGIN
                UPDATE p 
                SET p.IsActive_SMA = 1
                FROM WinLimit_ProductOffer p WITH (ROWLOCK, UPDLOCK)
                WHERE ProductID = @ProductID AND BetType = @Bettype
        END
        ELSE
        BEGIN
                INSERT INTO WinLimit_ProductOffer(ProductID, BetType, IsActive_SMA, IsActive_Company)
                VALUES (@ProductID, @Bettype, 1, 0)
        END

    ';

    SELECT @ScriptContent = REPLACE(@ScriptContent, '{RedmineID}', CAST(@RedmineID AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{RedmineID}', CAST(@RedmineID AS NVARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductId}', CAST(@ProductId AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{ProductId}', CAST(@ProductId AS NVARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductName}', @ProductName),
        @ScriptName = REPLACE(@ScriptName, '{ProductName}', @ProductName);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Sporttype}', CAST(@Sporttype AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{Sporttype}', CAST(@Sporttype AS NVARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Bettype}', CAST(@Bettype AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{Bettype}', CAST(@Bettype AS NVARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductType}', @ProductType),
        @ScriptName = REPLACE(@ScriptName, '{ProductType}', @ProductType);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{date}', FORMAT(GETDATE(), 'yyyyMMdd')),
        @ScriptName = REPLACE(@ScriptName, '{date}', FORMAT(GETDATE(), 'yyyyMMdd'));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Nickname}', @Nickname),
        @ScriptName = REPLACE(@ScriptName, '{Nickname}', @Nickname);

    RETURN CAST((
        SELECT 
            @ServerAlias AS ServerAlias,
            @DBName AS DBName,
            ScriptName, ScriptContent
        FROM (
                VALUES(@ScriptName, @ScriptContent)
        )  AS t (ScriptName, ScriptContent)
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    ) AS NVARCHAR(MAX));
END