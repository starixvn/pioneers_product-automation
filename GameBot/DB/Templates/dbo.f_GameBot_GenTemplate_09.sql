CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_09
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @ServerAlias VARCHAR(100) = N'DBCUST',
            @DBName VARCHAR(100) = N'CustDB'
            ;
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Comm_{date}_{RedmineID}_{ProductName}_Step9_Unknown.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBCUST-CustDB"></info>*/
    /*
            Created: {Nickname}@{date}
            Task: UAT - Add product setting for Licensees [redmine: #{RedmineID}]
            DB: DBCUST-CustDB
    */
    ---------------------------------------------------------------------------------
    
    ';

    SELECT @ScriptContent = REPLACE(@ScriptContent, '{RedmineID}', CAST(@RedmineID AS VARCHAR(10))),
            @ScriptName = REPLACE(@ScriptName, '{RedmineID}', CAST(@RedmineID AS VARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductId}', CAST(@ProductId AS VARCHAR(10))),
            @ScriptName = REPLACE(@ScriptName, '{ProductId}',  CAST(@ProductId AS VARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductName}', @ProductName),
            @ScriptName = REPLACE(@ScriptName, '{ProductName}', @ProductName);
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