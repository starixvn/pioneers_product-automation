--DBBOT.ProductBot_Intg
CREATE OR ALTER PROCEDURE dbo.GameBot_ProductSport_History
	@ProductName VARCHAR(100) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT @ProductName = ISNULL(@ProductName, '');
	IF @ProductName = ''
	BEGIN
		SELECT TOP(5) 
			ProductName, ProductID
			, CONCAT(CASE WHEN casinoTYpe = 1 THEN 'RNG' ELSE 'Live' END, ' Casino') AS ProductType
			, s.SportType, s.SportName
			, bt.BettypeRange
			, 1 AS IsHistory
		FROM bodb02.intg.Products p WITH(NOLOCK)
		INNER JOIN bodb02.intg.Sports s ON p.ProductName = s.SportName
		CROSS APPLY (
			SELECT CONCAT(MIN(bettype), '-', MAX(bettype)) AS BettypeRange
			FROM bodb02.intg.SportBettypeMatrix sp WITH(NOLOCK)
			WHERE sp.ProductID = p.ProductID AND sp.SportType = s.SportType
		) AS bt
		WHERE BalanceType = 3 AND CasinoType IN (1,2)
		ORDER BY p.ProductID DESC;
	END
	ELSE
	BEGIN
		SELECT TOP(1) 
			ProductName, ProductID
			, CONCAT(CASE WHEN casinoTYpe = 1 THEN 'RNG' ELSE 'Live' END, ' Casino') AS ProductType
			, s.SportType, s.SportName
			, bt.BettypeRange
			, 1 AS IsHistory
			, BalanceType
			, CasinoType
			, SubProductBalanceType
			, VendorID
			, 'History Detail' AS RecordType
		FROM bodb02.intg.Products p WITH(NOLOCK)
		INNER JOIN bodb02.intg.Sports s ON p.ProductName = s.SportName
		CROSS APPLY (
			SELECT CONCAT(MIN(bettype), '-', MAX(bettype)) AS BettypeRange
			FROM bodb02.intg.SportBettypeMatrix sp WITH(NOLOCK)
			WHERE sp.ProductID = p.ProductID AND sp.SportType = s.SportType
		) AS bt
		WHERE BalanceType = 3 AND CasinoType IN (1,2)
			AND p.ProductName = @ProductName
	END
END
GO

GRANT EXEC ON dbo.GameBot_ProductSport_History TO mcp_service;
GO

EXEC dbo.GameBot_ProductSport_History 'WOW Gaming'