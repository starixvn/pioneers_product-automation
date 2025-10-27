--DBBOT.Products_Intg
CREATE OR ALTER PROCEDURE dbo.GameBot_ProductSport_Validate
	@product_decode VARCHAR(MAX),
	@err_msg VARCHAR(250) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT @err_msg = ISNULL(@err_msg, '');

	IF @err_msg <> ''
	BEGIN
		-- Handle error message
		SELECT CAST(0 AS BIT) AS [is_valid]
			, @err_msg AS [err_msg];
		RETURN;
	END

	--- extract product data from JSON
	DECLARE @product_data TABLE (
		model VARCHAR(50),
		evn VARCHAR(50),
		product_type VARCHAR(100),
		product_id INT,
		product_name VARCHAR(100),
		product_code VARCHAR(10),
		product_setting VARCHAR(10),
		sport_id INT,
		sport_name VARCHAR(100),
		bettype_from INT,
		bettype_to INT,
		bettype_prize INT,
		bettype_contribution INT
	);

	INSERT INTO @product_data(
		model, evn,
		product_type, product_id, product_name, product_code, product_setting,
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

	-- You can now use @product_data for further processing
	DECLARE 
		@ProductId INT,
		@ProductName VARCHAR(100),
		@productCode VARCHAR(10),
		@Sporttype INT,
		@SportName VARCHAR(100),
		@BettypeFrom INT,
		@BettypeTo INT,
		@BettypePrize INT,
		@BettypeContribution INT
		;

	SELECT 
		@ProductId = product_id,
		@ProductName = product_name,
		@productCode = product_code,
		@Sporttype = sport_id,
		@SportName = sport_name,
		@BettypeFrom = bettype_from,
		@BettypeTo = bettype_to,
		@BettypePrize = bettype_prize,
		@BettypeContribution = bettype_contribution
	FROM @product_data;

	-- check existence in in Products, Sports, BetTypes tables
	BEGIN TRY
	
		IF EXISTS (SELECT TOP(1) 1 FROM bodb02.intg.Products WITH (NOLOCK) WHERE ProductID = @ProductId OR ProductName = @ProductName Or ProductPrefix = @productCode)
		BEGIN
			RAISERROR('ProductID: %d, ProductName: %s, ProductCode: %s existed in Products table.', 16, 1, @ProductId, @ProductName, @productCode);
		END
		IF EXISTS (SELECT TOP(1) 1 FROM bodb02.intg.Sports WITH (NOLOCK) WHERE SportType = @Sporttype OR SportName = @SportName)
		BEGIN
			RAISERROR('SportType: %d, SportName: %s existed in Sports table.', 16, 1, @Sporttype, @SportName);
		END
		IF EXISTS (SELECT TOP(1) 1 FROM bodb02.intg.BetType WITH (NOLOCK) WHERE TypeId BETWEEN @BettypeFrom AND @BettypeTo)
		BEGIN
			RAISERROR('BetType range: %d to %d existed in BetType table.', 16, 1, @BettypeFrom, @BettypeTo);
		END
	END TRY
	BEGIN CATCH
		SELECT @err_msg = ERROR_MESSAGE();
	END CATCH

	-- If all validations pass
	SELECT 
		CASE WHEN @err_msg = '' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [is_valid],
		@err_msg AS [err_msg]
END
GO

GRANT EXEC ON dbo.GameBot_ProductSport_Validate TO mcp_service;
GO
DECLARE @product_decode VARCHAR(MAX)='{"model":"Deposit","evn":"LOCAL","product_type":"Live","product_setting":"17_6","product_id":"117","product_name":"BB Play","product_code":"BBP","sport_id":"113","sport_name":"BB Play","bettype_from":"17100","bettype_to":"17199","bettype_prize":"17198","bettype_contribution":"17199"}'
	,@err_msg VARCHAR(250) = '';
EXEC dbo.GameBot_ProductSport_Validate @product_decode=@product_decode, @err_msg = @err_msg OUTPUT;