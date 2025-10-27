--DBBOT.ProductBot_Intg
CREATE OR ALTER PROCEDURE dbo.GameBot_ProductSport_Check
	@ProductName 		VARCHAR(50),
	@SportName 			VARCHAR(50) = NULL,
	@SlackChannel 		VARCHAR(50) = NULL,
	@SlackMsgTs 		VARCHAR(50) = NULL,
	@SlackUser 			VARCHAR(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@ProductId INT,
		@SportId INT;

	-- Set sport name default
	SELECT @SportName 	= COALESCE(NULLIF(@SportName, ''), @ProductName),
		@SlackChannel 	= COALESCE(NULLIF(@SlackChannel, ''), '#gamebot-integration'),
		@SlackMsgTs 	= COALESCE(NULLIF(@SlackMsgTs, ''), ''),
		@SlackUser 		= COALESCE(NULLIF(@SlackUser, ''), 'gamebot');
	;

	-- Check if product exists
	SELECT TOP (1) 
		@ProductId = ProductId
	FROM bodb02.intg.Products WITH (NOLOCK)
	WHERE ProductName = @ProductName;

	-- Check if sport exists
	SELECT TOP (1) 
		@SportId = SportType
	FROM bodb02.intg.Sports WITH (NOLOCK)
	WHERE SportName = @SportName;

	-- Check Bot processing status
	DECLARE @ProcessID INT = 0;
	SELECT TOP (1)
		@ProcessID = Id
	FROM ProductBot_Intg.dbo.[SetupTask] WITH (NOLOCK)
	WHERE [SetupStatus] IN ('Waiting', 'Running');

	IF (@ProcessID > 0)
	BEGIN
		-- Only allow one process at a time
		SELECT ProcessExisted = 1,
			ProcessError = 'Sorry, an integration process for game product is already running by <@' + @SlackUser + '>.';
		RETURN;
	END

	-- Return results based on existence checks
	IF @ProductId > 0
	BEGIN
		SELECT ProductExisted = 1;
		RETURN;
	END
	ELSE IF @SportId > 0
	BEGIN
		SELECT SportExisted = 1;
		RETURN;
	END
	ELSE 
	BEGIN
		DECLARE @ProductPrefix NVARCHAR(10),
			@ProductDecode NVARCHAR(MAX);

		SELECT @ProductPrefix = UPPER(LEFT(REPLACE(@ProductName, ' ', ''), 3));
		DROP TABLE IF EXISTS #NewProductSport;

		SELECT 
			t.ProductName,
			p.NewProductId,
			t.SportName,
			s.NewSportId,
			bt.BettypeFrom,
			BettypeTo = bt.BettypeFrom + 9,
			ProductPrefix = @ProductPrefix,
			ProductExisted = 0,
			SportExisted = 0
		INTO #NewProductSport
		FROM (VALUES (@ProductName, @SportName)) AS t(ProductName, SportName)
		CROSS APPLY (
			SELECT NewProductId = MAX(ProductId) + 1 
			FROM bodb02.intg.Products WITH (NOLOCK)
		) AS p
		CROSS APPLY (
			SELECT NewSportId = MIN(SportType) - 1 
			FROM bodb02.intg.Sports WITH (NOLOCK) 
			WHERE SportType > 99
		) AS s
		CROSS APPLY (
			SELECT BettypeFrom = MAX(BetType) + 1 
			FROM bodb02.intg.SportBettypeMatrix WITH (NOLOCK) 
			WHERE BetType < 19999
		) AS bt;

		-- Construct Product Decode from #NewProductSport to json-like string
		SELECT 
			@ProductDecode = (
				SELECT NewProductId, ProductName, NewSportId, SportName, BettypeFrom, BettypeTo, ProductPrefix
				FROM #NewProductSport 
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			);

		INSERT INTO ProductBot_Intg.dbo.[SetupTask]
			([ProductDecode]
			,[SlackChannel]
			,[SlackMessage_ts]
			,[SlackUser]
			,[SetupStatus]
			,[CreatedTime])
		SELECT 
			@ProductDecode,
			@SlackChannel,
			@SlackMsgTs,
			@SlackUser,
			'Waiting',
			GETUTCDATE()
		WHERE NOT EXISTS (
			SELECT 1 
			FROM ProductBot_Intg.dbo.[SetupTask] WITH (NOLOCK)
			WHERE [SetupStatus] = 'Waiting'
		);
		IF @@ROWCOUNT > 0
		BEGIN
			SELECT 
				NewProductId,
				ProductName,
				NewSportId,
				SportName,
				BettypeFrom,
				BettypeTo,
				ProductPrefix,
				ProductExisted,
				SportExisted
			FROM #NewProductSport;
		END
		ELSE
		BEGIN
			SELECT ProcessExisted = 1,
				ProcessError = 'Sorry, an integration process is already running by <@' + @SlackUser + '>. Please try again later.';
		END
	END
END
GO

GRANT EXECUTE ON dbo.GameBot_ProductSport_Check TO mcp_service;
GO

-- Test execution
DECLARE @ProductName NVARCHAR(50) = 'BBPlay',
		@SportName NVARCHAR(50) = NULL;

EXEC dbo.GameBot_ProductSport_Check @ProductName, @SportName;