CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_15
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot',
    @Sporttype INT = 0,
    @Bettype INT = 0
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @ServerAlias VARCHAR(100) = N'DBCUST',
        @DBName VARCHAR(100) = N'CustDB'
        ;
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Scr02_{date}_{RedmineID}_{ProductName}_SportNonOfferedSiteCurrency.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBCUST-CustDB"></info>*/
        /*
                Created: {Nickname}@{date}
                Task: {ProductName} - Integrate new Live Casino product - Implement Setting and Initial data [RedmineID: #{RedmineID}]
                DB: DBCUST-CustDB
        */
        USE CustDB
        GO

        DECLARE @ProductID TINYINT = {ProductId},
                        @Sporttype SMALLINT = {Sporttype},
                        @Bettype INT = {Bettype};

        INSERT INTO SportNonOfferedSiteCurrency(SportType, BetType, Currency, SiteID, RealProductId, RepUpdateTime)
        SELECT @Sporttype AS SportType, @Bettype AS BetType, exchangeid AS Currency, 0 AS SiteID, @ProductID AS RealProductId, dbo.f_GetDateTime2() AS RepUpdateTime
        FROM exchange (NOLOCK)
        WHERE IsActive = 1 
                And OfferSite IN (0,1) 
                AND currency NOT IN (''RM'',''HKK'',''RMB'',
                ''US$'',''Yen'',''$US'',''UT'',''USD'',''Won'',''THB'',
                ''IN'',''IND'',''IDD'',''IDR'',''DDD'',''INH'',''YNG'',''UUS'')

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