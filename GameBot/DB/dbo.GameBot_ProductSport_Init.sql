--DBBOT.ProductBot_Intg
USE ProductBot_Intg;
GO
CREATE OR ALTER PROCEDURE dbo.GameBot_ProductSport_Init
    @product_decode VARCHAR(MAX),
    @action_mode TINYINT = 0    -- 0: Insert/Update, 1: Export Excel, 2: Both
AS
BEGIN
    SET NOCOUNT ON;
    --select @product_decode = '{"model":"Deposit","evn":"LOCAL","product_type":"Live","product_setting":"17_6","product_id":"117","product_name":"BB Play","product_code":"BBP","sport_id":"113","sport_name":"BB Play","bettype_from":"17100","bettype_to":"17199","bettype_prize":"17198","bettype_contribution":"17199"}';
    DECLARE
        @ErrCode	INT = 0,
        @ErrMsg		NVARCHAR(250)= '';

    DECLARE @product_data TABLE (
        model VARCHAR(50),
        evn VARCHAR(50),
        product_type VARCHAR(100),
        product_id VARCHAR(50),
        product_name VARCHAR(100),
        product_code VARCHAR(10),
        sport_id VARCHAR(50),
        sport_name VARCHAR(100),
        bettype_from VARCHAR(50),
        bettype_to VARCHAR(50),
        bettype_prize VARCHAR(50),
        bettype_contribution VARCHAR(50)
    );

    INSERT INTO @product_data(
        model, evn, product_type, product_id, product_name, product_code,
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
        JSON_VALUE(@product_decode, '$.sport_id') AS sport_id,
        JSON_VALUE(@product_decode, '$.sport_name') AS sport_name,
        JSON_VALUE(@product_decode, '$.bettype_from') AS bettype_from,
        JSON_VALUE(@product_decode, '$.bettype_to') AS bettype_to,
        JSON_VALUE(@product_decode, '$.bettype_prize') AS bettype_prize,
        JSON_VALUE(@product_decode, '$.bettype_contribution') AS bettype_contribution;

    -- You can now use @product_data for further processing
    DECLARE @UserID	INT = 8,
        @LoginIP VARCHAR(15) = '127.0.0.1';

    DECLARE @New_ProductID INT,
        @ProductOrderNo INT = 0,
        @BalanceType TINYINT = 3,
        @CasinoType TINYINT = 1;

    SELECT @New_ProductID = product_id FROM @product_data;
    SELECT @ProductOrderNo = ISNULL(MAX(OrderNo), 0) + 1 
    FROM bodb02.intg.Products WITH(NOLOCK) WHERE ProductID >= (@New_ProductID-1);
    -- Create ProductFile XML
    DECLARE @ProductFile XML;
    SET @ProductFile = (
        SELECT 
            product_id AS [@ProductID],
            product_name AS [@ProductName],
            product_name AS [@Description],
            product_code AS [@ProductPrefix],
            '1' AS [@Enabled],
            NULL AS [@EndOfSupportDate],
            @BalanceType AS [@BalanceType],
            '' AS [@SubProductBalanceType],
            '' AS [@GroupType],
            @CasinoType AS [@CasinoType],
            '0' AS [@IsOfferPlayForFun],
            product_id AS [@VendorID],
            @ProductOrderNo AS [@OrderNo],
            '1' AS [@Environment]
        FROM @product_data
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    -- Create Product3rdFile XML
    DECLARE @Product3rdFile XML;
    SET @Product3rdFile = (
        SELECT 
            product_id AS [@ProductId],
            product_name AS [@ProductName],
            product_name AS [@Description],
            product_code AS [@ProductPrefix],
            '1' AS [@OfferSingle],
            '1' AS [@ApplyDCS],
            '1' AS [@Enabled],
            NULL AS [@EndOfSupportDate],
            '0' AS [@OfferSite]
        FROM @product_data
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    ) ;

    -- Create SportFile XML
    DECLARE @SportFile XML;
    SET @SportFile = (
        SELECT 
            sport_id AS [@SportType],
            sport_name AS [@SportName],
            '' AS [@SportNameCh],
            '' AS [@SportNameCs], 
            '' AS [@SportNameJp], 
            '' AS [@SportNameIt],
            '' AS [@SportNameTh],
            '0' AS [@ParlayMaxPayout],
            '' AS [@SportNameKo],
            '' AS [@SportNameES],
            '' AS [@SportNameVN],
            '' AS [@SportNameEL],
            '' AS [@SportNameRU],
            '' AS [@SportNameID],
            '' AS [@SportNamePT],
            '' AS [@SportNameFR],
            '' AS [@SportNameMMR],
            '' AS [@SportNamePL],
            '' AS [@SportNameHI]
        FROM @product_data
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    -- Create BettypeFile XML
    DECLARE @BettypeFile XML;
    DECLARE @bettype_from INT, @bettype_to INT;
    SELECT @bettype_from = CAST(bettype_from AS INT), @bettype_to = CAST(bettype_to AS INT) FROM @product_data;

    -- Create a recursive CTE to generate numbers in the range
    WITH BetTypeRange AS (
        -- Base case: start with the first value
        SELECT @bettype_from AS bettype
        UNION ALL
        
        -- Recursive part: increment until we reach the maximum
        SELECT bettype + 1
        FROM BetTypeRange
        WHERE bettype < @bettype_to
    )
    -- Set the BettypeFile XML
    SELECT @BettypeFile = (
        SELECT 
            bettype AS [@typeid],
            CONCAT('Upcoming ', bettype) AS [@typenamee],
            '' AS [@typenamec],
            '' AS [@typedesc],
            '' AS [@typenamec_uni],
            '' AS [@typenamej],
            '' AS [@typenamcn],
            '' AS [@typenamecn],
            '' AS [@typenameth],
            '' AS [@typenameit],
            '' AS [@typenameko],
            '' AS [@typenameES],
            '' AS [@typenameVN],
            '' AS [@typenameEL],
            '' AS [@typenamee_Eu],
            '' AS [@typenameRU],
            '' AS [@typenameID],
            '' AS [@typenamePT],
            '' AS [@typenameFR],
            bettype AS [@ParentTypeid],
            '' AS [@typenameMMR],
            '' AS [@typenameHI],
            bettype AS [@DisplayedTypeID],
            '0' AS [@LicSpreadBetTypeGroupId],
            '1' AS [@Is3rdParty]
        FROM BetTypeRange
        
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    )
    OPTION (MAXRECURSION 0);

    -- Create a recursive CTE to generate numbers in the range for SportBettypeMatrix
    DECLARE @SportBettypeMatrixFile XML,
        @ProductType VARCHAR(50),
        @EventType TINYINT = 0,
        @RefTable TINYINT = 0;
    
    DECLARE @sport_id INT, @product_id INT, @bettype_prize INT, @bettype_contribution INT, @sport_ref INT = 0;
    SELECT @RefTable = CASE WHEN product_type = 'RNG' THEN 1 ELSE 2 END,
        @ProductType = product_type,
        @sport_id = CAST(sport_id AS INT),
        @product_id = CAST(product_id AS INT),
        @bettype_prize = CAST(bettype_prize AS INT),
        @bettype_contribution = CAST(bettype_contribution AS INT)
    FROM @product_data;

    SELECT @sport_ref = @sport_id;
    WITH BetTypeMatrix AS (
        -- Base case: start with the first value
        SELECT @bettype_from AS bettype
        
        UNION ALL
        
        -- Recursive part: increment until we reach the maximum
        SELECT bettype + 1
        FROM BetTypeMatrix
        WHERE bettype < @bettype_to
    )
    -- Set the SportBettypeMatrixFile XML
    SELECT @SportBettypeMatrixFile = (
        SELECT 
            @sport_id AS [@SportType],
            bettype AS [@BetType],
            '0' AS [@IsLive],
            @product_id AS [@ProductID],
            '1' AS [@Enabled],
            '0' AS [@IsTest],
            @EventType AS [@EventType],
            CASE 
                WHEN bettype = @bettype_prize THEN 'Jackpot Prize' 
                WHEN bettype = @bettype_contribution THEN 'Jackpot Contribution'
                ELSE '' END AS [@SubProduct],
            @RefTable AS [@RefTable],
            ExtraInfo AS [@ExtraInfo]
        FROM BetTypeMatrix        
        OUTER APPLY(
            SELECT (SELECT 
                CASE WHEN @sport_ref > 0 THEN @sport_ref END AS SportTypeRef,
                CASE WHEN bettype IN (@bettype_prize, @bettype_contribution) THEN bettype END AS BettypeRef,
                CASE 
                    WHEN bettype = @bettype_prize THEN 'Prize' 
                    WHEN bettype = @bettype_contribution THEN 'Contribution' 
                END AS BettypeGroup
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS ExtraInfo
        ) AS ex (ExtraInfo)
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    )
    OPTION (MAXRECURSION 0);

    -- Create RefResourceFile XML
    DECLARE @RefResourceFile XML;
    SET @RefResourceFile = (
        SELECT 
            RefId AS [@RefId],
            ResourceId AS [@ResourceId],
            Resource_en AS [@Resource_en],
            Resource_ch AS [@Resource_ch],
            Resource_cs AS [@Resource_cs],
            Resource_jp AS [@Resource_jp],
            Resource_it AS [@Resource_it],
            Resource_th AS [@Resource_th],
            Resource_ko AS [@Resource_ko],
            Resource_es AS [@Resource_es],
            Sort1 AS [@Sort1],
            Sort2 AS [@Sort2],
            Resource_el AS [@Resource_el],
            Resource_vn AS [@Resource_vn],
            Resource_pl AS [@Resource_pl],
            Resource_id AS [@Resource_id],
            Resource_hi AS [@Resource_hi],
            Resource_mm AS [@Resource_mm],
            Resource_fr AS [@Resource_fr],
            Resource_ru AS [@Resource_ru],
            Resource_pt AS [@Resource_pt],
            Resource_de AS [@Resource_de]
        FROM (
            SELECT
                'Product' AS RefId,
                product_id AS ResourceId,
                product_name AS Resource_en,
                '' AS Resource_ch,
                '' AS Resource_cs,
                '' AS Resource_jp,
                '' AS Resource_it,
                '' AS Resource_th,
                '' AS Resource_ko,
                '' AS Resource_es,
                '' AS Sort1,
                '' AS Sort2,
                '' AS Resource_el,
                '' AS Resource_vn,
                '' AS Resource_pl,
                '' AS Resource_id,
                '' AS Resource_hi,
                '' AS Resource_mm,
                '' AS Resource_fr,
                '' AS Resource_ru,
                '' AS Resource_pt,
                '' AS Resource_de
            FROM @product_data
            UNION ALL
            SELECT
                'Product_Sport_BT' AS RefId,
                CONCAT(product_id, '_', @bettype_from) AS ResourceId,
                product_name AS Resource_en,
                '' AS Resource_ch,
                '' AS Resource_cs,
                '' AS Resource_jp,
                '' AS Resource_it,
                '' AS Resource_th,
                '' AS Resource_ko,
                '' AS Resource_es,
                '' AS Sort1,
                '' AS Sort2,
                '' AS Resource_el,
                '' AS Resource_vn,
                '' AS Resource_pl,
                '' AS Resource_id,
                '' AS Resource_hi,
                '' AS Resource_mm,
                '' AS Resource_fr,
                '' AS Resource_ru,
                '' AS Resource_pt,
                '' AS Resource_de
            FROM @product_data
        ) AS t
        FOR XML PATH('File'), ROOT('ROOT'), TYPE
    );

    BEGIN TRY
        DECLARE 
            @ProductData NVARCHAR(MAX)      = CAST(@ProductFile AS NVARCHAR(MAX)),
            @Product3rdData NVARCHAR(MAX)   = CAST(@Product3rdFile AS NVARCHAR(MAX)),
            @SportData NVARCHAR(MAX)        = CAST(@SportFile AS NVARCHAR(MAX)),
            @BettypeData NVARCHAR(MAX)      = CAST(@BettypeFile AS NVARCHAR(MAX)),
            @SportBettypeMatrixData NVARCHAR(MAX) = CAST(@SportBettypeMatrixFile AS NVARCHAR(MAX)),
            @RefResourceData NVARCHAR(MAX)  = CAST(@RefResourceFile AS NVARCHAR(MAX))
        ;
        -- DBPRO.bodb02
        EXEC DBPRO.bodb02.dbo.GameBot_ProductSport_InsUpd
            @ProductData                = @ProductData,
            @SportData                  = @SportData,
            @BettypeData                = @BettypeData,
            @SportBettypeMatrixData     = @SportBettypeMatrixData,
            @RefResourceData            = @RefResourceData;

        --DBCUST.CustDB
        EXEC DBCUST.CustDB.dbo.GameBot_ProductSetting_InsUpd
            @Product3rdData             = @Product3rdData
    END TRY
    BEGIN CATCH
        SET @ErrCode = 101;
        SET @ErrMsg = ERROR_MESSAGE();
    END CATCH

    -- Insert BotTask record
    DECLARE @InsertedTaskId INT, @SetupId INT = 0;
    SELECT TOP(1) @SetupId = ISNULL(MAX(Id), 0) 
    FROM ProductBot_Intg.dbo.[SetupTask] WITH (NOLOCK)
    WHERE JSON_VALUE(ProductDecode, '$.product_id') = @New_ProductID;

    WITH CTE_Events AS (
        SELECT 'products' AS table_name,
        (
            SELECT 
                X.e.value('@ProductID', 'INT') AS ProductID,
                X.e.value('@ProductName', 'VARCHAR(100)') AS ProductName,
                X.e.value('@Description', 'VARCHAR(100)') AS Description,
                X.e.value('@ProductPrefix', 'VARCHAR(10)') AS ProductPrefix,
                X.e.value('@Enabled', 'BIT') AS Enabled,
                X.e.value('@EndOfSupportDate', 'DATE') AS EndOfSupportDate,
                X.e.value('@BalanceType', 'TINYINT') AS BalanceType,
                X.e.value('@SubProductBalanceType', 'VARCHAR(50)') AS SubProductBalanceType,
                X.e.value('@GroupType', 'VARCHAR(50)') AS GroupType,
                X.e.value('@CasinoType', 'TINYINT') AS CasinoType,
                X.e.value('@IsOfferPlayForFun', 'BIT') AS IsOfferPlayForFun,
                X.e.value('@VendorID', 'INT') AS VendorID,
                X.e.value('@OrderNo', 'INT') AS OrderNo,
                X.e.value('@Environment', 'TINYINT') AS Environment
            FROM @ProductFile.nodes('/ROOT/File') AS X(e)
            WHERE @action_mode IN (1, 2)
            FOR JSON PATH
        ) AS table_data
        UNION ALL
        SELECT 'product3rd',
        (
            SELECT 
                X.e.value('@ProductId', 'VARCHAR(50)') AS ProductId,
                X.e.value('@ProductName', 'VARCHAR(100)') AS ProductName,
                X.e.value('@Description', 'VARCHAR(100)') AS Description,
                X.e.value('@ProductPrefix', 'VARCHAR(10)') AS ProductPrefix,
                X.e.value('@OfferSingle', 'BIT') AS OfferSingle,
                X.e.value('@ApplyDCS', 'BIT') AS ApplyDCS,
                X.e.value('@Enabled', 'BIT') AS Enabled,
                X.e.value('@EndOfSupportDate', 'VARCHAR(50)') AS EndOfSupportDate,
                X.e.value('@OfferSite', 'BIT') AS OfferSite
            FROM @Product3rdFile.nodes('/ROOT/File') AS X(e)
            WHERE @action_mode IN (1, 2)
            FOR JSON PATH
        ) AS table_data
        UNION ALL
        SELECT 'sports',
        (
            SELECT 
                X.e.value('@SportType', 'INT') AS SportType,
                X.e.value('@SportName', 'NVARCHAR(100)') AS SportName,
                X.e.value('@SportNameCh', 'NVARCHAR(100)') AS SportNameCh,
                X.e.value('@SportNameCs', 'NVARCHAR(100)') AS SportNameCs,
                X.e.value('@SportNameJp', 'NVARCHAR(100)') AS SportNameJp,
                X.e.value('@SportNameIt', 'NVARCHAR(100)') AS SportNameIt,
                X.e.value('@SportNameTh', 'NVARCHAR(100)') AS SportNameTh,
                X.e.value('@ParlayMaxPayout', 'DECIMAL(18,2)') AS ParlayMaxPayout,
                X.e.value('@SportNameKo', 'NVARCHAR(100)') AS SportNameKo,
                X.e.value('@SportNameES', 'NVARCHAR(100)') AS SportNameES,
                X.e.value('@SportNameVN', 'NVARCHAR(100)') AS SportNameVN,
                X.e.value('@SportNameEL', 'NVARCHAR(100)') AS SportNameEL,
                X.e.value('@SportNameRU', 'NVARCHAR(100)') AS SportNameRU,
                X.e.value('@SportNameID', 'NVARCHAR(100)') AS SportNameID,
                X.e.value('@SportNamePT', 'NVARCHAR(100)') AS SportNamePT,
                X.e.value('@SportNameFR', 'NVARCHAR(100)') AS SportNameFR,
                X.e.value('@SportNameMMR', 'NVARCHAR(100)') AS SportNameMMR,
                X.e.value('@SportNamePL', 'NVARCHAR(100)') AS SportNamePL,
                X.e.value('@SportNameHI', 'NVARCHAR(100)') AS SportNameHI
            FROM @SportFile.nodes('/ROOT/File') AS X(e)
            WHERE @action_mode IN (1, 2)
            FOR JSON PATH
        ) AS sports
        UNION ALL
        SELECT 'bettypes',
        (
            SELECT 
                X.e.value('@typeid', 'INT') AS typeid,
                X.e.value('@typenamee', 'NVARCHAR(100)') AS typenamee,
                X.e.value('@typenamec', 'NVARCHAR(100)') AS typenamec,
                X.e.value('@typedesc', 'NVARCHAR(250)') AS typedesc,
                X.e.value('@typenamec_uni', 'NVARCHAR(100)') AS typenamec_uni,
                X.e.value('@typenamej', 'NVARCHAR(100)') AS typenamej,
                X.e.value('@typenamcn', 'NVARCHAR(100)') AS typenaamcn,
                X.e.value('@typenamecn', 'NVARCHAR(100)') AS typenamecn,
                X.e.value('@typenameth', 'NVARCHAR(100)') AS typenaameth,
                X.e.value('@typenameit', 'NVARCHAR(100)') AS typenameit,
                X.e.value('@typenameko', 'NVARCHAR(100)') AS typenameko,
                X.e.value('@typenameES', 'NVARCHAR(100)') AS typenameES,
                X.e.value('@typenameVN', 'NVARCHAR(100)') AS typenameVN,
                X.e.value('@typenameEL', 'NVARCHAR(100)') AS typenameEL,
                X.e.value('@typenamee_Eu', 'NVARCHAR(100)') AS typenamee_Eu,
                X.e.value('@typenameRU', 'NVARCHAR(100)') AS typenameRU,
                X.e.value('@typenameID', 'NVARCHAR(100)') AS typenameID,
                X.e.value('@typenamePT', 'NVARCHAR(100)') AS typenamePT,
                X.e.value('@typenameFR', 'NVARCHAR(100)') AS typenameFR,
                X.e.value('@ParentTypeid', 'INT') AS ParentTypeid,
                X.e.value('@typenameMMR', 'NVARCHAR(100)') AS typenameMMR,
                X.e.value('@typenameHI', 'NVARCHAR(100)') AS typenameHI,
                X.e.value('@DisplayedTypeID', 'INT') AS DisplayedTypeID,
                X.e.value('@LicSpreadBetTypeGroupId', 'INT') AS LicSpreadBetTypeGroupId,
                X.e.value('@Is3rdParty', 'BIT') AS Is3rdParty
            FROM @BettypeFile.nodes('/ROOT/File') AS X(e)
            WHERE @action_mode IN (1, 2)
            FOR JSON PATH
        ) AS bettypes
        UNION ALL
        SELECT 'sportbettypematrix',
        (
            SELECT 
                X.e.value('@SportType', 'INT') AS SportType,
                X.e.value('@BetType', 'INT') AS BetType,
                X.e.value('@IsLive', 'BIT') AS IsLive,
                X.e.value('@ProductID', 'INT') AS ProductID,
                X.e.value('@Enabled', 'BIT') AS Enabled,
                X.e.value('@IsTest', 'BIT') AS IsTest,
                X.e.value('@EventType', 'INT') AS EventType,
                X.e.value('@SubProduct', 'VARCHAR(100)') AS SubProduct,
                X.e.value('@RefTable', 'INT') AS RefTable,
                X.e.value('@ExtraInfo', 'VARCHAR(1000)') AS ExtraInfo
            FROM @SportBettypeMatrixFile.nodes('/ROOT/File') AS X(e)
            WHERE @action_mode IN (1, 2)
            FOR JSON PATH
        ) AS sbmt
        UNION ALL
        SELECT 'refresource',
        (
            SELECT 
                X.e.value('@RefId', 'VARCHAR(50)') AS RefId,
                X.e.value('@ResourceId', 'VARCHAR(50)') AS ResourceId,
                X.e.value('@Resource_en', 'NVARCHAR(100)') AS Resource_en,
                X.e.value('@Resource_ch', 'NVARCHAR(100)') AS Resource_ch,
                X.e.value('@Resource_cs', 'NVARCHAR(100)') AS Resource_cs,
                X.e.value('@Resource_jp', 'NVARCHAR(100)') AS Resource_jp,
                X.e.value('@Resource_it', 'NVARCHAR(100)') AS Resource_it,
                X.e.value('@Resource_th', 'NVARCHAR(100)') AS Resource_th,
                X.e.value('@Resource_ko', 'NVARCHAR(100)') AS Resource_ko,
                X.e.value('@Resource_es', 'NVARCHAR(100)') AS Resource_es,
                X.e.value('@Sort1', 'VARCHAR(50)') AS Sort1,
                X.e.value('@Sort2', 'VARCHAR(50)') AS Sort2,
                X.e.value('@Resource_el', 'NVARCHAR(100)') AS Resource_el,
                X.e.value('@Resource_vn', 'NVARCHAR(100)') AS Resource_vn,
                X.e.value('@Resource_pl', 'NVARCHAR(100)') AS Resource_pl,
                X.e.value('@Resource_id', 'NVARCHAR(100)') AS Resource_id,
                X.e.value('@Resource_hi', 'NVARCHAR(100)') AS Resource_hi,
                X.e.value('@Resource_mm', 'NVARCHAR(100)') AS Resource_mm,
                X.e.value('@Resource_fr', 'NVARCHAR(100)') AS Resource_fr,
                X.e.value('@Resource_ru', 'NVARCHAR(100)') AS Resource_ru,
                X.e.value('@Resource_pt', 'NVARCHAR(100)') AS Resource_pt,
                X.e.value('@Resource_de', 'NVARCHAR(100)') AS Resource_de
            FROM @RefResourceFile.nodes('/ROOT/File') AS X(e)
            WHERE @action_mode IN (1, 2)
            FOR JSON PATH
        ) AS refresource
    )
    INSERT INTO ProductBot_Intg.dbo.[BotTask]
    (SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime)
    SELECT SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime
    FROM (
        VALUES(@SetupId, 'Global Agent', 'Global tables to Excel', 'Done', GETDATE())
    ) AS t (SetupId, BotName, TaskName, BotStatus, CreatedTime)
    CROSS APPLY (
        SELECT (
            SELECT error, err_msg, action_mode, events
            FROM (
                SELECT @ErrCode AS error, @ErrMsg AS err_msg, @action_mode AS action_mode,
                (
                    SELECT table_name, table_data
                    FROM CTE_Events
                    FOR JSON PATH 
                ) AS events
            ) AS rs
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS BotResult
    ) AS rs;
    SET @InsertedTaskId = SCOPE_IDENTITY();
    
    -- Final error check
    SELECT TOP(1)
        TaskId, SetupId, BotName, TaskName, BotResult, BotStatus, CreatedTime
    FROM ProductBot_Intg.dbo.[BotTask] WITH (NOLOCK)
    WHERE TaskId = @InsertedTaskId
    ORDER BY TaskId DESC
END
GO

GRANT EXEC ON dbo.GameBot_ProductSport_Init TO mcp_service;
GO
--Test Execution
DECLARE @product_decode VARCHAR(MAX)='{"model":"Deposit","evn":"LOCAL","product_type":"Live","product_setting":"17_6","product_id":"118","product_name":"BobbyBot","product_code":"BBP","sport_id":"113","sport_name":"BobbyBot","bettype_from":"19000","bettype_to":"19009","bettype_prize":"0","bettype_contribution":"19009"}'
EXEC dbo.GameBot_ProductSport_Init @product_decode, @action_mode=2
GO