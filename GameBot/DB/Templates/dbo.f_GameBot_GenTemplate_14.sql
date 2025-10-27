CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_14
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot',
    @Sporttype INT = 0,
    @Bettype INT = 0,
    @Credit_psID INT = 0,
    @SettingType TINYINT = 0,
    @MaxChoice TINYINT = 0,
    @Child_DisplayOrder TINYINT = 0
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @ServerAlias VARCHAR(100) = N'DBCUST',
        @DBName VARCHAR(100) = N'CustDB'
        ;
    SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
    DECLARE @ScriptName NVARCHAR(200) = N'Scr01_{date}_{RedmineID}_{ProductName}_Credit_AddProductProfile.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias=""DBCUST-CustDB""></info>*/
        /*
                Created: {Nickname}@{date}
                Task: {ProductName} - Integrate new Live Casino product - Implement Setting and Initial data [RedmineID: #{RedmineID}]
                DB: DBCUST-CustDB
        */
        USE CustDB
        GO

        DECLARE  @SportType         INT = {Sporttype}
                ,@BetType           INT = {Bettype}
                ,@psID              INT = {Credit_psID}
                ,@Child_DisplayOrder TINYINT = {Child_DisplayOrder}
                ,@MaxChoice          TINYINT = {MaxChoice}
                ,@SettingType        TINYINT = {SettingType}

        -- Product Setting Profile
        INSERT INTO ProductSettingProfile(
                [ProductSettingID]
                ,[SettingType]
                ,[SportType]
                ,[BetType]
                ,[IsLive]
                ,[ProductID]
                ,[IsSync]
                ,[IsHidden]
                ,[IsDisabled]
                ,[SettingLevel]
                ,[DisplayOrder]
                ,[SettingStatus]
                ,[RealProductId]
                ,[Child_DisplayOrder]
                ,[GroupID]
                ,[GroupType]
                ,[GroupTypeOrder]
                ,[CreationStatus]
                ,[DisplayType]
                ,[MarketType]
                ,[RepUpdateTime]
                ,[MaxChoice]
                ,[OfferType]
        )
        SELECT @psID AS ProductSettingID,
                @SettingType,
                @SportType,
                @BetType,
                0 AS IsLive,
                41 AS ProductID,
                0 AS IsSync,
                1 AS IsHidden,
                0 AS IsDisabled,
                2 AS SettingLevel,
                6 AS DisplayOrder,
                1 AS SettingStatus,
                41 AS RealProductID,
                @Child_DisplayOrder,
                3 AS GroupID,
                158 AS GroupType,
                5 AS GroupTypeOrder,
                1 AS CreationStatus,
                1 AS DisplayType,
                0 AS MarketType,
                dbo.f_GetDateTime2(),
                @MaxChoice AS MaxChoice,
                0 AS OfferType

        -- Product Setting Profile
        INSERT INTO ProductSettingDetail(
                [ProductSettingID]
                ,[SettingType]
                ,[SportType]
                ,[BetType]
                ,[IsLive]
                ,[ProductID]
                ,[IsSync]
                ,[IsHidden]
                ,[IsDisabled]
                ,[SettingLevel]
                ,[DisplayOrder]
                ,[SettingStatus]
                ,[RealProductId]
                ,[Child_DisplayOrder]
                ,[RepUpdateTime]
                ,[MaxChoice]
        )
        SELECT @psID AS ProductSettingID,
                @SettingType,
                @SportType AS SportType,
                @BetType AS BetType,
                0 AS IsLive,
                41 AS ProductID,
                0 AS IsSync,
                1 AS IsHidden,
                0 AS IsDisabled,
                2 AS SettingLevel,
                6 AS DisplayOrder,
                1 AS SettingStatus,
                41 AS RealProductID,
                @Child_DisplayOrder,
                dbo.f_GetDateTime2(),
                @MaxChoice
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

    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Sporttype}', @Sporttype);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Bettype}', @Bettype);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Credit_psID}', @Credit_psID);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{Child_DisplayOrder}', @Child_DisplayOrder);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{MaxChoice}', @MaxChoice);
    SELECT @ScriptContent = REPLACE(@ScriptContent, '{SettingType}', @SettingType);

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