CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_12
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot',
    @Sporttype INT = 0,
    @Bettype INT = 0,
    @BitmapOrder TINYINT = 0,
    @Deposit_psID INT = 0
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @ServerAlias VARCHAR(100) = N'DBGLOB',
        @DBName VARCHAR(100) = N'GlobCustDB'
        ;
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Scr03_{date}_{RedmineID}_{ProductName}_Deposit_AddProductProfile.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBGLOB-GlobCustDB"></info>*/
        /*
                Created by: {Nickname}@{date}
                Task: initial data for {ProductName} [Redmine: #{RedmineID}] 
                DB: DBGLOB-GlobCustDB
        */
        USE GlobCustDB
        GO

        ----------------------------------------------------------------------------------
        DECLARE  @ProductID SMALLINT = {ProductId}
                        ,@SportType  SMALLINT = {Sporttype}
                        ,@Bettype       SMALLINT = {Bettype}  
                        ,@BitmapOrder TINYINT = {BitmapOrder}
                        ,@psID        INT = {Deposit_psID}

        ----------------------------------------------------------------------------------
        ----------------------------------------------------------------------------------
        --Insert setting:
        INSERT INTO Dep_ProductStatusProfile(SportType,Bettype,BitmapOrder, RepUpdateTime)
        SELECT t.SportType,t.Bettype,t.BitmapOrder,t.RepUpdateTime
        FROM (
            SELECT @SportType AS SportType, @Bettype AS Bettype, @BitmapOrder AS BitmapOrder, dbo.f_Getdatetime2() AS RepUpdateTime
        ) AS t (SportType,Bettype,BitmapOrder, RepUpdateTime)
        LEFT JOIN Dep_ProductStatusProfile PSP WITH (NOLOCK)
            ON PSP.SportType = t.SportType
                AND PSP.Bettype = t.Bettype
        WHERE PSP.SportType IS NULL

        INSERT INTO [dbo].[Dep_ProductSetting]
                ([ProductSettingID]
                ,[ProductID]
                ,[SettingType]
                ,[TemplateID]
                ,[DisplayOrder]
                ,[SettingLevel]
                , RepUpdateTime)
        SELECT t.[ProductSettingID]
				,t.[ProductID]
				,t.[SettingType]
				,t.[TemplateID]
				,t.[DisplayOrder]
				,t.[SettingLevel]
				,t.RepUpdateTime
        FROM (
            SELECT @psID, @ProductID, 4, 0, 1, 1,         dbo.f_Getdatetime2()
            UNION 
            SELECT @psID+1, @ProductID, 1, 0, 2, 1,         dbo.f_Getdatetime2()
            UNION 
            SELECT @psID+2, @ProductID, 9, 0, 3, 1,         dbo.f_Getdatetime2()
        ) AS t ([ProductSettingID],[ProductID],[SettingType],[TemplateID],[DisplayOrder],[SettingLevel], RepUpdateTime)
        LEFT JOIN Dep_ProductSetting PS WITH (NOLOCK)
            ON PS.ProductID = t.ProductID
        WHERE PS.ProductID IS NULL

        INSERT INTO [dbo].[Dep_ProductSettingDetail]
            ([ProductSettingID]
            ,[SportType]
            ,[BetType]
            ,[IsLive]
            ,[MaxDefaultValue]
            ,[SettingStatus]
            ,[MinDefaultValue]
            ,[IsApplyBA]
            ,RepUpdateTime)
        SELECT 
			t.[ProductSettingID]
			,t.[SportType]
			,t.[BetType]
			,t.[IsLive]
			,t.[MaxDefaultValue]
			,t.[SettingStatus]
			,t.[MinDefaultValue]
			,t.[IsApplyBA]
			,t.RepUpdateTime
        FROM (
            SELECT @psID, @SportType, @Bettype, 0, 0, 1, NULL, 0,         dbo.f_Getdatetime2()
            UNION 
            SELECT @psID+1, @SportType, @Bettype, 0, 0, 1, NULL, 0,         dbo.f_Getdatetime2()
            UNION 
            SELECT @psID+2, @SportType, @Bettype, 0, 0, 1, NULL, 0,         dbo.f_Getdatetime2()
        ) AS t ([ProductSettingID],[SportType],[BetType],[IsLive],[MaxDefaultValue],[SettingStatus],[MinDefaultValue],[IsApplyBA], RepUpdateTime)
        LEFT JOIN Dep_ProductSettingDetail PSD WITH (NOLOCK)
            ON PSD.SportType = t.SportType
                AND PSD.BetType = t.BetType
        WHERE PSD.ProductSettingID IS NULL
        GO
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
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{BitmapOrder}', CAST(@BitmapOrder AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{BitmapOrder}', CAST(@BitmapOrder AS NVARCHAR(10)));
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Deposit_psID}', CAST(@Deposit_psID AS NVARCHAR(10))),
        @ScriptName = REPLACE(@ScriptName, '{Deposit_psID}', CAST(@Deposit_psID AS NVARCHAR(10)));
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