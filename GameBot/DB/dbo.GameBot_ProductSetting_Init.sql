--DBBOT.ProductBot_Intg
USE ProductBot_Intg;
GO
CREATE OR ALTER PROCEDURE dbo.GameBot_ProductSetting_Init
    @product_decode VARCHAR(MAX),
    @username VARCHAR(100) = 'GameBot'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @ErrCode INT = 0,
        @ErrMsg NVARCHAR(250)= '';

    DECLARE @product_data TABLE (
        model VARCHAR(50),
        evn VARCHAR(50),
        product_type VARCHAR(100),
        product_id VARCHAR(50),
        product_name VARCHAR(100),
        product_code VARCHAR(10),
        product_setting VARCHAR(10),
        sport_id VARCHAR(50),
        sport_name VARCHAR(100),
        bettype_from VARCHAR(50),
        bettype_to VARCHAR(50),
        bettype_prize VARCHAR(50),
        bettype_contribution VARCHAR(50)
    );

    INSERT INTO @product_data(
        model, evn, product_type, product_id, product_name, product_code, product_setting,
        sport_id, sport_name, bettype_from, bettype_to, 
        bettype_prize, bettype_contribution
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
        JSON_VALUE(@product_decode, '$.bettype_contribution') AS bettype_contribution;

    DECLARE @UserID INT = 8,
        @LoginIP VARCHAR(15) = '127.0.0.1',
        @New_ProductID INT,
        @product_type VARCHAR(50);

    SELECT TOP 1 @New_ProductID = CAST(product_id AS INT)
        ,@product_type = product_type
    FROM @product_data;

    DECLARE @ProductStatusProfileFile XML,
        @bitmapOrder INT = 1;
    SELECT @bitmapOrder = ISNULL(MAX(bitmapOrder), 0) + 1
    FROM CustDB.intg.ProductStatusProfile WITH(NOLOCK);

    SELECT @ProductStatusProfileFile = (
        SELECT 
            pd.product_name AS [@ProductName],
            pd.product_id AS [@ProductID],
            pd.sport_id AS [@Sporttype],
            CONCAT(pd.bettype_from, '') AS [@Bettype],
            @bitmapOrder AS [@bitmapOrder],
            'Yes' AS [@Remark]
        FROM @product_data pd
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    DECLARE @ProductSettingDetailFile XML,
        @ProductSettingID INT = 0;

    SELECT @ProductSettingID = ISNULL(MAX(ProductSettingID), 0) + 1
    FROM CustDB.intg.ProductSettingDetail WITH(NOLOCK); 

    SELECT @ProductSettingDetailFile = (
        SELECT 
            CONCAT(FORMAT(GETDATE(), 'yyyyMMdd'), '@', @username, ': ', product_name) AS [@remark],
            @ProductSettingID + 1 AS [@ProductSettingID],
            st.SettingType AS [@SettingType],
            pd.sport_id AS [@SportType],
            pd.bettype_from AS [@BetType],
            0 AS [@IsLive],
            '41' AS [@ProductID],
            NULL AS [@MaxPT],
            NULL AS [@MaxDiscount],
            0 AS [@IsSync],
            1 AS [@IsHidden],
            0 AS [@IsDisabled],
            2 AS [@SettingLevel],
            6 AS [@DisplayOrder],
            0 AS [@SettingStatus],
            NULL AS [@IntervalValue],
            41 AS [@RealProductId],
            st.MaxChoice AS [@MaxChoice],
            NULL AS [@Parent_ProductSettingID],
            '' AS [@Child_DisplayOrder],
            NULL AS [@SubType]
        FROM @product_data pd
        CROSS APPLY (
            SELECT SUBSTRING(product_setting,1, CHARINDEX('_',product_setting)-1) AS SettingType
            ,SUBSTRING(product_setting,CHARINDEX('_',product_setting)+1, 2) AS MaxChoice
        ) AS st
        WHERE @product_type = 'LIVE'
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    DECLARE @Dep_ProductStatusProfileFile XML,
        @Dep_bitmapOrder INT = 1;
    SELECT @Dep_bitmapOrder = ISNULL(MAX(bitmapOrder), 0) + 1 
    FROM GlobCustDB.intg.Dep_ProductStatusProfile WITH(NOLOCK);

    SELECT @Dep_ProductStatusProfileFile = (
        SELECT 
            pd.product_name AS [@ProductName],
            pd.product_id AS [@ProductID],
            pd.sport_id AS [@Sporttype],
            CONCAT(pd.bettype_from, '') AS [@Bettype],
            @Dep_bitmapOrder AS [@bitmapOrder],
            FORMAT(GETDATE(), 'yyyy-MM-dd') AS [@Remark]
        FROM @product_data pd
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    DECLARE @Dep_ProductSettingFile XML,
        @Dep_ProductSettingID INT,
        @DisplayOrder INT = 0;
    SELECT @Dep_ProductSettingID = ISNULL(MAX(ProductSettingID), 0)
    FROM GlobCustDB.intg.Dep_ProductSetting WITH(NOLOCK);

    SELECT @Dep_ProductSettingFile = (
        SELECT 
            ProductName AS [@ProductName],    
            @Dep_ProductSettingID + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [@ProductSettingID], 
            ProductID AS [@ProductID], 
            SettingType AS [@SettingType], 
            TemplateID AS [@TemplateID], 
            @DisplayOrder + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS [@DisplayOrder], 
            SettingLevel AS [@SettingLevel]
        FROM (
            SELECT
                pd.product_name AS [ProductName],
                pd.product_id AS [ProductID],
                '4' AS [SettingType],     
                0 AS [TemplateID],        
                '1' AS [SettingLevel]     
            FROM @product_data pd
            UNION ALL
            SELECT
                pd.product_name AS [ProductName],
                pd.product_id AS [ProductID],
                '7' AS [SettingType],     
                0 AS [TemplateID],        
                '1' AS [SettingLevel]     
            FROM @product_data pd
            WHERE pd.product_type = 'Live'
            UNION ALL
            SELECT
                pd.product_name AS [ProductName],
                pd.product_id AS [ProductID],
                '1' AS [SettingType],     
                0 AS [TemplateID],        
                '1' AS [SettingLevel]     
            FROM @product_data pd
            UNION ALL
            SELECT
                pd.product_name AS [ProductName],
                pd.product_id AS [ProductID],
                '9' AS [SettingType],     
                0 AS [TemplateID],        
                '1' AS [SettingLevel]     
            FROM @product_data pd
        ) AS tmp
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    DECLARE @SBSMFile XML;
    DECLARE @EventType TINYINT = 0,
        @RefTable TINYINT = 0,
        @ModelType TINYINT = 0,
        @IsRNG BIT = 0;

    SELECT @RefTable = CASE WHEN product_type = 'RNG' THEN 1 ELSE 2 END,
        @IsRNG = CASE WHEN product_type = 'RNG' THEN 1 ELSE 0 END,
        @ModelType = CASE 
            WHEN model = 'Credit' THEN 1 
            WHEN model = 'Deposit' THEN 2
            ELSE 0 END
    FROM @product_data;

    WITH BetTypeRange AS (
        SELECT 
            CAST(bettype_from AS INT) AS bettype,
            CAST(bettype_from AS INT) AS bettype_from,
            CAST(bettype_to AS INT) AS bettype_to,
            sport_id, product_id, bettype_prize, bettype_contribution
        FROM @product_data
        UNION ALL
        SELECT 
            bettype + 1,
            bettype_from,
            bettype_to,
            sport_id, product_id, bettype_prize, bettype_contribution
        FROM BetTypeRange
        WHERE bettype < bettype_to
    )
    SELECT @SBSMFile = (
        SELECT 
            [@SportType], [@BetType], [@IsLicensee], [@IsLive], [@Site],
            [@SportTypeRefPT], [@BetTypeRefPT], [@IsLivePT], [@TablePT],
            [@SportTypeRefComm], [@BetTypeRefComm], [@TableComm],
            [@SportTypeRefBetSetting], [@BetTypeRefBetSetting], [@TableBetSetting],
            [@TableBettrans], [@SporttypeRefWinlossLimit], [@BettypeRefWinlossLimit],
            [@RealProductId], [@DummyProductId]
        FROM (
            SELECT 
                CONCAT(sport_id,'') AS [@SportType],
                CAST(bettype AS VARCHAR(50)) AS [@BetType],
                '0' AS [@IsLicensee],
                '0' AS [@IsLive],
                'ALL' AS [@Site],
                IIF(@IsRNG = 1, '9906', '9911') AS [@SportTypeRefPT],
                IIF(@IsRNG = 1, '4001', '2400') AS [@BetTypeRefPT],
                '0' AS [@IsLivePT],
                'CustPTSetting3rd_member' AS [@TablePT],
                IIF(@IsRNG = 1, '', '9911') AS [@SportTypeRefComm],
                IIF(@IsRNG = 1, '', '2400') AS [@BetTypeRefComm],
                IIF(@IsRNG = 1, '', 'CustDiscount3rd_Member') AS [@TableComm],
                CONCAT(sport_id,'') AS [@SportTypeRefBetSetting],
                CONCAT(bettype_from,'') AS [@BetTypeRefBetSetting],
                IIF(@IsRNG = 1, 'ProductStakeLevelGroup', 'CustStakeLevel_Member') AS [@TableBetSetting],
                IIF(@IsRNG = 1, 'bettransRNG', 'bettransLC') AS [@TableBettrans],
                IIF(@IsRNG = 0 AND bettype = bettype_from, '9911', '') AS [@SporttypeRefWinlossLimit],
                IIF(@IsRNG = 0 AND bettype = bettype_from, '2400', '') AS [@BettypeRefWinlossLimit],
                CONCAT(product_id,'') AS [@RealProductId],
                IIF(@IsRNG = 1, '53', '41') AS [@DummyProductId]
            FROM BetTypeRange
            WHERE @ModelType IN (0, 1)
            UNION ALL
            SELECT 
                CONCAT(sport_id,'') AS [@SportType],
                CAST(bettype AS VARCHAR(50)) AS [@BetType],
                '1' AS [@IsLicensee],
                '0' AS [@IsLive],
                'ALL' AS [@Site],
                CONCAT(sport_id,'') AS [@SportTypeRefPT],
                CONCAT(bettype_from,'') AS [@BetTypeRefPT],
                '0' AS [@IsLivePT],
                'Dep_CustPTSetting_Member' AS [@TablePT],
                CONCAT(sport_id,'') AS [@SportTypeRefComm],
                CONCAT(bettype_from,'') AS [@BetTypeRefComm],
                'Dep_CustDiscountSetting_Member' AS [@TableComm],
                CONCAT(sport_id,'') AS [@SportTypeRefBetSetting],
                CONCAT(bettype_from,'') AS [@BetTypeRefBetSetting],
                IIF(@IsRNG = 1, 'Dep_ProductStakeLevelGroup', 'Dep_CustStakeLevel_Member') AS [@TableBetSetting],
                IIF(@IsRNG = 1, 'bettransRNG', 'bettransLC') AS [@TableBettrans],
                '' AS [@SporttypeRefWinlossLimit],
                '' AS [@BettypeRefWinlossLimit],
                CONCAT(product_id,'') AS [@RealProductId],
                IIF(@IsRNG = 1, '53', '41') AS [@DummyProductId]
            FROM BetTypeRange
            WHERE @ModelType IN (0, 2)
        ) AS aio
        FOR XML PATH('Setting'), ROOT('ROOT'), TYPE
    )
    OPTION (MAXRECURSION 0);

    BEGIN TRY
        DECLARE 
            @ProductStatusProfileData NVARCHAR(MAX)         = CAST(@ProductStatusProfileFile AS NVARCHAR(MAX)),
            @ProductSettingDetailData NVARCHAR(MAX)         = CAST(@ProductSettingDetailFile AS NVARCHAR(MAX)),
            @Dep_ProductStatusProfileData NVARCHAR(MAX)     = CAST(@Dep_ProductStatusProfileFile AS NVARCHAR(MAX)),
            @Dep_ProductSettingData NVARCHAR(MAX)           = CAST(@Dep_ProductSettingFile AS NVARCHAR(MAX)),
            @SBSMFileData NVARCHAR(MAX)                     = CAST(@SBSMFile AS NVARCHAR(MAX))
        ;
        --DBCUST.CustDB
        EXEC DBCUST.CustDB.dbo.GameBot_ProductSetting_InsUpd
            @ProductStatusProfileData = @ProductStatusProfileData,
            @ProductSettingDetailData = @ProductSettingDetailData,
            @Dep_ProductStatusProfileData = @Dep_ProductStatusProfileData,
            @Dep_ProductSettingData = @Dep_ProductSettingData,
            @SBSMFileData = @SBSMFileData
    END TRY
    BEGIN CATCH
        SET @ErrCode = 101;
        SET @ErrMsg = ERROR_MESSAGE();
    END CATCH

    DECLARE @InsertedTaskId INT, @SetupId INT = 0;
    SELECT TOP(1) @SetupId = ISNULL(MAX(Id), 0) 
    FROM ProductBot_Intg.dbo.[SetupTask] WITH (NOLOCK)
    WHERE JSON_VALUE(ProductDecode, '$.product_id') = @New_ProductID;

    WITH CTE_Setting AS (
        SELECT 'ProductStatusProfile' AS table_name
            ,(
                SELECT
                    T.c.value('@ProductName', 'NVARCHAR(100)') AS ProductName,
                    T.c.value('@ProductID', 'INT') AS ProductID,
                    T.c.value('@Sporttype', 'INT') AS Sporttype,
                    T.c.value('@Bettype', 'INT') AS Bettype,
                    T.c.value('@bitmapOrder', 'INT') AS bitmapOrder,
                    T.c.value('@Remark', 'NVARCHAR(50)') AS [Remark Apply CanSee]
                FROM @ProductStatusProfileFile.nodes('/ROOT/File') AS T(c)
                FOR JSON PATH
            ) as table_data
        UNION ALL
        SELECT 'ProductSettingDetail' AS table_name,
        (
            SELECT
                T.c.value('@remark', 'NVARCHAR(50)') AS remark,
                T.c.value('@ProductSettingID', 'INT') AS ProductSettingID,
                T.c.value('@SettingType', 'INT') AS SettingType,
                T.c.value('@SportType', 'INT') AS SportType,
                T.c.value('@BetType', 'INT') AS BetType,
                T.c.value('@IsLive', 'BIT') AS IsLive,
                T.c.value('@ProductID', 'INT') AS ProductID,
                T.c.value('@MaxPT', 'INT') AS MaxPT,
                T.c.value('@MaxDiscount', 'INT') AS MaxDiscount,
                T.c.value('@IsSync', 'BIT') AS IsSync,
                T.c.value('@IsHidden', 'BIT') AS IsHidden,
                T.c.value('@IsDisabled', 'BIT') AS IsDisabled,
                T.c.value('@SettingLevel', 'INT') AS SettingLevel,
                T.c.value('@DisplayOrder', 'INT') AS DisplayOrder,
                T.c.value('@SettingStatus', 'INT') AS SettingStatus,
                T.c.value('@IntervalValue', 'NVARCHAR(50)') AS IntervalValue,
                T.c.value('@RealProductId', 'INT') AS RealProductId,
                T.c.value('@MaxChoice', 'INT') AS MaxChoice,
                T.c.value('@Parent_ProductSettingID', 'INT') AS Parent_ProductSettingID,
                T.c.value('@Child_DisplayOrder', 'NVARCHAR(50)') AS Child_DisplayOrder,
                T.c.value('@SubType', 'NVARCHAR(50)') AS SubType
            FROM @ProductSettingDetailFile.nodes('/ROOT/File') AS T(c)
            FOR JSON PATH
        ) as table_data
        WHERE @product_type = 'LIVE'
        UNION ALL
        SELECT 'Dep_ProductStatusProfile' AS table_name,
            (
                SELECT
                    T.c.value('@ProductName', 'NVARCHAR(100)') AS ProductName,
                    T.c.value('@ProductID', 'INT') AS ProductID,
                    T.c.value('@Sporttype', 'INT') AS Sporttype,
                    T.c.value('@Bettype', 'INT') AS Bettype,
                    T.c.value('@bitmapOrder', 'INT') AS bitmapOrder,
                    T.c.value('@Remark', 'NVARCHAR(50)') AS Remark
                FROM @Dep_ProductStatusProfileFile.nodes('/ROOT/File') AS T(c)
                FOR JSON PATH
            ) as table_data
        UNION ALL
        SELECT 'Dep_ProductSetting' AS table_name,
        (
            SELECT
                T.c.value('@ProductName', 'NVARCHAR(100)') AS ProductName,
                T.c.value('@ProductSettingID', 'INT') AS ProductSettingID,
                T.c.value('@ProductID', 'INT') AS ProductID,
                T.c.value('@SettingType', 'INT') AS SettingType,
                T.c.value('@TemplateID', 'INT') AS TemplateID,
                T.c.value('@DisplayOrder', 'INT') AS DisplayOrder,
                T.c.value('@SettingLevel', 'INT') AS SettingLevel
            FROM @Dep_ProductSettingFile.nodes('/ROOT/File') AS T(c)
            FOR JSON PATH
        ) as table_data
        UNION ALL
        SELECT 'SportBettypeSettingMatrix' AS table_name,
        (
            SELECT
                T.c.value('@SportType', 'INT') AS SportType,
                T.c.value('@BetType', 'INT') AS BetType,
                T.c.value('@IsLicensee', 'BIT') AS IsLicensee,
                T.c.value('@IsLive', 'BIT') AS IsLive,
                T.c.value('@Site', 'NVARCHAR(50)') AS Site,
                T.c.value('@SportTypeRefPT', 'NVARCHAR(50)') AS SportTypeRefPT,
                T.c.value('@BetTypeRefPT', 'NVARCHAR(50)') AS BetTypeRefPT,
                T.c.value('@IsLivePT', 'BIT') AS IsLivePT,
                T.c.value('@TablePT', 'NVARCHAR(100)') AS TablePT,
                T.c.value('@SportTypeRefComm', 'NVARCHAR(50)') AS SportTypeRefComm,
                T.c.value('@BetTypeRefComm', 'NVARCHAR(50)') AS BetTypeRefComm,
                T.c.value('@TableComm', 'NVARCHAR(100)') AS TableComm,
                T.c.value('@SportTypeRefBetSetting', 'NVARCHAR(50)') AS SportTypeRefBetSetting,
                T.c.value('@BetTypeRefBetSetting', 'NVARCHAR(50)') AS BetTypeRefBetSetting,
                T.c.value('@TableBetSetting', 'NVARCHAR(100)') AS TableBetSetting,
                T.c.value('@TableBettrans', 'NVARCHAR(100)') AS TableBettrans,
                T.c.value('@SporttypeRefWinlossLimit', 'NVARCHAR(50)') AS SporttypeRefWinlossLimit,
                T.c.value('@BettypeRefWinlossLimit', 'NVARCHAR(50)') AS BettypeRefWinlossLimit,
                T.c.value('@RealProductId', 'INT') AS RealProductId,
                T.c.value('@DummyProductId', 'INT') AS DummyProductId
            FROM @SBSMFile.nodes('/ROOT/Setting') AS T(c)
            FOR JSON PATH
        ) as table_data
    ),
    CTE_BotResult AS (
        SELECT(
            SELECT @ErrCode AS error, @ErrMsg AS err_msg
            , (
                SELECT table_name, table_data 
                FROM CTE_Setting bs
                FOR JSON PATH
            ) AS settings
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS BotResult
    )
    INSERT INTO ProductBot_Intg.dbo.[BotTask]
    (SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime)
    SELECT SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime
    FROM (
        VALUES(@SetupId, 'Setting Agent', 'Initial product setting', 'Done', GETDATE())
    ) AS t (SetupId, BotName, TaskName, BotStatus, CreatedTime)
    CROSS APPLY CTE_BotResult;
    SELECT @InsertedTaskId = SCOPE_IDENTITY();

    SELECT TOP(1)
        TaskId, SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime
    FROM ProductBot_Intg.dbo.[BotTask] WITH (NOLOCK)
    WHERE TaskId = @InsertedTaskId
    ORDER BY TaskId DESC
END
GO

GRANT EXEC ON dbo.GameBot_ProductSetting_Init TO mcp_service;
GO
--Test Execution
-- DECLARE @product_decode VARCHAR(MAX)='{"model":"Deposit","evn":"LOCAL","product_type":"RNG","product_setting":"17_6","product_id":"122","product_name":"BB Play","product_code":"BBP","sport_id":"113","sport_name":"BB Play","bettype_from":"17100","bettype_to":"17199","bettype_prize":"17198","bettype_contribution":"17199"}'
-- EXEC dbo.GameBot_ProductSetting_Init @product_decode, @username='Tester'
