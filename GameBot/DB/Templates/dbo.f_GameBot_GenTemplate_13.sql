CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_13
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
        @ServerAlias VARCHAR(100) = N'DBGLOB',
        @DBName VARCHAR(100) = N'GlobCustDB'
        ;
    
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Scr04_{date}_{RedmineID}_{ProductName}_Deposit_UpdateSettingStatus_PRO.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBGLOB-GlobCustDB"></info>*/
    /*
            Created by: {Nickname}@{date}
            Task: initial data for {ProductName}  [Redmine: #{RedmineID}] 
            DB: DBGLOB-GlobCustDB
    */
    USE GlobCustDB
    GO

    DECLARE  @SportType SMALLINT = {Sporttype}
                    ,@Bettype        SMALLINT = {Bettype}  
                    
    UPDATE 
    [dbo].[Dep_ProductSettingDetail] WITH (ROWLOCK, UPDLOCK)
    SET SettingStatus=0
            ,RepUpdateTime=dbo.f_GetDateTime2()
    WHERE SportType = @SportType
    AND BetType = @Bettype
    GO';

    SELECT @ScriptContent = REPLACE(@ScriptContent, '{RedmineID}', CAST(@RedmineID AS VARCHAR(10))),
            @ScriptName = REPLACE(@ScriptName, '{RedmineID}', CAST(@RedmineID AS VARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductId}', CAST(@ProductId AS VARCHAR(10))),
            @ScriptName = REPLACE(@ScriptName, '{ProductId}',  CAST(@ProductId AS VARCHAR(10)));
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