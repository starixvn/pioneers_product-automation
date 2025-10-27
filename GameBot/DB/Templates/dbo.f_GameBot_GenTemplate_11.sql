CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_11
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @ServerAlias VARCHAR(100) = N'DBPRO',
            @DBName VARCHAR(100) = N'bodb02'
            ;
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Scr02_{date}_{RedmineID}_{ProductName}_UpdateEnv_PROD.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBPRO-bodb02"></info>*/
        /*
                Created by: {Nickname}@{date}
                Task: Update Products.Environment [Redmine: #{RedmineID}] 
                DB: DBPRO-bodb02
        */
        USE bodb02
        GO

        DECLARE  @ProductID        SMALLINT = {ProductId}

        UPDATE p 
                SET P.Environment = 0
                ,RepUpdateTime=dbo.f_GetDateTime2()
        FROM Products p WITH (ROWLOCK , UPDLOCK)
        WHERE P.ProductID = @ProductID
        GO
    ';

    SELECT @ScriptContent = REPLACE(@ScriptContent, '{RedmineID}', CAST(@RedmineID AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{RedmineID}', CAST(@RedmineID AS NVARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductId}', CAST(@ProductId AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{ProductId}', CAST(@ProductId AS NVARCHAR(10)));
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