--DBBOT.ProductBot_Intg
USE ProductBot_Intg;
GO
CREATE OR ALTER PROCEDURE dbo.GameBot_SettingScript_Init
    @product_decode VARCHAR(MAX),
    @username VARCHAR(100) NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @ErrCode    INT = 0,
        @ErrMsg     NVARCHAR(250)= '';

    DECLARE @product_data TABLE (
        model VARCHAR(50),
        evn VARCHAR(50),
        product_type VARCHAR(100),
        product_id VARCHAR(50),
        product_name VARCHAR(100),
        product_code VARCHAR(10),
        product_setting VARCHAR(50),
        sport_id VARCHAR(50),
        sport_name VARCHAR(100),
        bettype_from VARCHAR(50),
        bettype_to VARCHAR(50),
        bettype_prize VARCHAR(50),
        bettype_contribution VARCHAR(50),
        feature_id INT
    );

    INSERT INTO @product_data(
        model, evn, product_type, product_id, product_name, product_code,product_setting,
        sport_id, sport_name, bettype_from, bettype_to, 
        bettype_prize, bettype_contribution, feature_id
    )
    SELECT 
        JSON_VALUE(@product_decode, '$.model') AS model,
        JSON_VALUE(@product_decode, '$.evn') AS evn,
        JSON_VALUE(@product_decode, '$.product_type') AS product_type,
        JSON_VALUE(@product_decode, '$.product_id') AS product_id,
        JSON_VALUE(@product_decode, '$.product_name') AS product_name,
        JSON_VALUE(@product_decode, '$.product_code') AS product_code,
        JSON_VALUE(@product_decode, '$.product_setting') AS product_setting,
        JSON_VALUE(@product_decode, '$.sport_id') AS sport_id,
        JSON_VALUE(@product_decode, '$.sport_name') AS sport_name,
        JSON_VALUE(@product_decode, '$.bettype_from') AS bettype_from,
        JSON_VALUE(@product_decode, '$.bettype_to') AS bettype_to,
        JSON_VALUE(@product_decode, '$.bettype_prize') AS bettype_prize,
        JSON_VALUE(@product_decode, '$.bettype_contribution') AS bettype_contribution,
        JSON_VALUE(@product_decode, '$.feature_id') AS feature_id;

    DECLARE @MaxCustID INT,
        @UserID INT = 8,
        @LoginIP VARCHAR(15) = '127.0.0.1';

    DECLARE @RedmineID INT = 12345;
    DECLARE @ProductId INT,
        @ProductName VARCHAR(100),
        @Nickname VARCHAR(100) = ISNULL(@username, 'GameBot'),
        @Sporttype INT,
        @Bettype INT,
        @ProductType VARCHAR(20) = 'RNG',
        @ProductSetting VARCHAR(50) = '0_0';

    DECLARE @BitmapOrder    TINYINT,
        @Deposit_psID       INT,
        @Credit_psID        INT,
        @SettingType        TINYINT,
        @MaxChoice          TINYINT,
        @Child_DisplayOrder TINYINT = 0;

    SELECT @ProductId = product_id, 
        @ProductName = product_name,
        @Sporttype = sport_id,
        @Bettype = bettype_from,
        @ProductType = product_type,
        @ProductSetting = product_setting,
        @RedmineID = ISNULL(feature_id, product_id)
    FROM @product_data;

    SELECT @MaxCustID = ISNULL(MAX(CustID), 0)
    FROM CustDB.intg.custInfo WITH(NOLOCK);

    SELECT @BitmapOrder = MAX(BitmapOrder) + 1
    FROM GlobCustDB.intg.Dep_ProductStatusProfile WITH(NOLOCK);

    SELECT @Deposit_psID = MAX(ProductSettingID) + 1
    FROM GlobCustDB.intg.Dep_ProductSetting WITH(NOLOCK);

    SELECT @Credit_psID = MAX(ProductSettingID) + 1
    FROM CustDB.intg.ProductSettingProfile WITH(NOLOCK);

    SELECT @SettingType = SUBSTRING(@ProductSetting,1, CHARINDEX('_',@ProductSetting)-1),
           @MaxChoice = SUBSTRING(@ProductSetting,CHARINDEX('_',@ProductSetting)+1, 1);

    DECLARE @Template_01 NVARCHAR(MAX),
        @Template_02 NVARCHAR(MAX),
        @Template_03 NVARCHAR(MAX),
        @Template_04 NVARCHAR(MAX),
        @Template_05 NVARCHAR(MAX),
        @Template_06 NVARCHAR(MAX),
        @Template_07 NVARCHAR(MAX),
        @Template_08 NVARCHAR(MAX),
        @Template_09 NVARCHAR(MAX),
        @Template_10 NVARCHAR(MAX),
        @Template_11 NVARCHAR(MAX),
        @Template_12 NVARCHAR(MAX),
        @Template_13 NVARCHAR(MAX),
        @Template_14 NVARCHAR(MAX),
        @Template_15 NVARCHAR(MAX),
        @Template_16 NVARCHAR(MAX)
        ; 

    SELECT @Template_01 = dbo.f_GameBot_GenTemplate_01(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_02 = dbo.f_GameBot_GenTemplate_02(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_03 = dbo.f_GameBot_GenTemplate_03(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_04 = dbo.f_GameBot_GenTemplate_04(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_05 = dbo.f_GameBot_GenTemplate_05(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_06 = dbo.f_GameBot_GenTemplate_06(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_07 = dbo.f_GameBot_GenTemplate_07(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_08 = dbo.f_GameBot_GenTemplate_08(@RedmineID, @ProductId, @ProductName, @Nickname);
    -- SELECT @Template_09 = dbo.f_GameBot_GenTemplate_09(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_10 = dbo.f_GameBot_GenTemplate_10(@RedmineID, @ProductId, @ProductName, @Nickname, @Sporttype, @Bettype, @ProductType);
    SELECT @Template_11 = dbo.f_GameBot_GenTemplate_11(@RedmineID, @ProductId, @ProductName, @Nickname);
    SELECT @Template_12 = dbo.f_GameBot_GenTemplate_12(@RedmineID, @ProductId, @ProductName, @Nickname, @Sporttype, @Bettype, @BitmapOrder, @Deposit_psID);
    SELECT @Template_13 = dbo.f_GameBot_GenTemplate_13(@RedmineID, @ProductId, @ProductName, @Nickname, @Sporttype, @Bettype);
    SELECT @Template_14 = dbo.f_GameBot_GenTemplate_14(@RedmineID, @ProductId, @ProductName, @Nickname, @Sporttype, @Bettype, @Credit_psID, @SettingType, @MaxChoice, @Child_DisplayOrder);
    SELECT @Template_15 = dbo.f_GameBot_GenTemplate_15(@RedmineID, @ProductId, @ProductName, @Nickname, @Sporttype, @Bettype);
    SELECT @Template_16 = dbo.f_GameBot_GenTemplate_16(@RedmineID, @ProductId, @ProductName, @Nickname, @Sporttype, @Bettype);

    DROP TABLE IF EXISTS #Templates;
    SELECT ENV, max_custid, ScriptNo, ScriptContent, RunAble, RunOrder
    INTO #Templates
    FROM (
        VALUES
            ('UAT', @maxCustid, 1,  @Template_01, 1, 5),
            ('UAT', @maxCustid, 2,  @Template_02, 1, 6),
            ('UAT', @maxCustid, 3,  @Template_03, 0, 7),
            ('UAT', @maxCustid, 4,  @Template_04, 1, 8),
            ('PRO', @maxCustid, 5,  @Template_05, 0, 10),
            ('PRO', @maxCustid, 6,  @Template_06, 0, 11),
            ('PRO', @maxCustid, 7,  @Template_07, 0, 12),
            ('PRO', @maxCustid, 8,  @Template_08, 0, 13),
            ('ALL', @maxCustid, 10, @Template_10, 1, 2),
            ('PRO', @maxCustid, 11, @Template_11, 0, 16),
            ('ALL', @maxCustid, 12, @Template_12, 1, 1),
            ('PRO', @maxCustid, 13, @Template_13, 0, 14),
            ('ALL', @maxCustid, 14, @Template_14, 1, 3),
            ('ALL', @maxCustid, 15, @Template_15, 1, 4),
            ('PRO', @maxCustid, 16, @Template_16, 0, 15)
    ) AS T (ENV, max_custid, ScriptNo, ScriptContent, RunAble, RunOrder)
    WHERE ScriptNo <= CASE WHEN @ProductType = 'RNG' THEN 13 ELSE 16 END;

    DECLARE @InsertedTaskId INT, @SetupId INT = 0;
    SELECT TOP(1) @SetupId = ISNULL(MAX(Id), 0) 
    FROM ProductBot_Intg.dbo.[SetupTask] WITH (NOLOCK)
    WHERE JSON_VALUE(ProductDecode, '$.product_id') = @ProductId;

    WITH CTE_BotResult AS (
        SELECT (
            SELECT error_code, error_message, templates
            FROM (
                SELECT @ErrCode AS error_code, @ErrMsg AS error_message,
                    (
                        SELECT ENV, max_custid, ScriptNo, JSON_VALUE(ScriptContent, '$.ScriptName') AS ScriptName
                        FROM #Templates
                        FOR JSON PATH
                    ) AS templates
            ) AS rs
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS BotResult
    )
    INSERT INTO ProductBot_Intg.dbo.[BotTask]
    (SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime)
    SELECT SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime
    FROM (
        VALUES(@SetupId, 'Setting Agent', 'Initial setting scripts', 'Done', GETDATE())
    ) AS t (SetupId, BotName, TaskName, BotStatus, CreatedTime)
    CROSS APPLY CTE_BotResult;
    SELECT @InsertedTaskId = SCOPE_IDENTITY();

    SELECT ENV, max_custid, ScriptNo, ScriptContent, RunAble, RunOrder
    FROM #Templates
    ORDER BY ScriptNo ASC;

END
GO

GRANT EXEC ON dbo.GameBot_SettingScript_Init TO mcp_service;
GO
-- DECLARE @product_decode VARCHAR(MAX)='{"model":"Deposit","evn":"LOCAL","product_type":"Live","product_setting":"17_6","product_id":"122","product_name":"BB Play","product_code":"BBP","sport_id":"113","sport_name":"BB Play","bettype_from":"17100","bettype_to":"17199","bettype_prize":"17198","bettype_contribution":"17199"}'
-- EXEC dbo.GameBot_SettingScript_Init @product_decode, 'GameBotUser'
