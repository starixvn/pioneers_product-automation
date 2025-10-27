CREATE OR ALTER PROCEDURE dbo.GameBot_ProductSport_StatusUpdate
	@Channel NVARCHAR(100) = '#gamebot-integration',
	@Status VARCHAR(10) = 'Completed',
	@Product NVARCHAR(MAX) = NULL,
	@BotMessage NVARCHAR(MAX) = NULL,
	@SlackMessage_ts VARCHAR(50) = NULL

AS
BEGIN
	SET NOCOUNT ON;

	SELECT @Product = ISNULL(@Product, '');
	SELECT @BotMessage = ISNULL(@BotMessage, '');
	-- UPDATE the status of the game product setup task
	IF (@Status = 'Messaging') 
	BEGIN
		-- UPDATE Products to mark as configuring
		UPDATE st WITH (ROWLOCK)
		SET st.[BotMessage] = @BotMessage,
			st.[SlackMessage_ts] = ISNULL(@SlackMessage_ts, '')
		FROM ProductBot_Intg.dbo.[SetupTask] st 
		WHERE st.[SetupStatus] IN ('Waiting')
			AND st.SlackChannel = @Channel;
	END
	ELSE 
	BEGIN
		-- UPDATE Products to mark as completed
		UPDATE st WITH (ROWLOCK)
		SET st.[SetupStatus] = @Status,
			st.ProductDecode = IIF(@Status = 'Running' AND ISJSON(@Product) = 1, @Product, st.ProductDecode)
		FROM ProductBot_Intg.dbo.[SetupTask] st 
		CROSS APPLY (
			SELECT TOP(1) Id
			FROM ProductBot_Intg.dbo.[SetupTask] st2 WITH (NOLOCK)
			WHERE st2.SlackChannel = st.SlackChannel
			ORDER BY st2.Id DESC
		) AS ca
		WHERE st.SlackChannel = @Channel
			AND st.Id = ca.Id
			AND (
				st.[SetupStatus] IN ('Waiting', 'Running') 
				OR @Status = 'Waiting' --force to Waiting
			)
		;
	END

	-- RETURN the number of rows affected
	SELECT TOP(1) Id AS [SetupId],
		st.SlackChannel AS channel,
		BotMessage AS [message], 
		SlackMessage_ts AS [message_ts],
		JSON_VALUE(ProductDecode, '$.product_name') AS ProductName,
		JSON_VALUE(ProductDecode, '$.sport_name') AS SportName,
		st.SetupStatus
	FROM ProductBot_Intg.dbo.[SetupTask] st WITH (NOLOCK)
	WHERE st.SlackChannel = @Channel
	ORDER BY st.Id DESC;

END
GO

GRANT EXECUTE ON dbo.GameBot_ProductSport_StatusUpdate TO mcp_service;
GO

-- TEST execution
EXEC dbo.GameBot_ProductSport_StatusUpdate @Channel = 'C09N4170762', @Status = 'Completed';
GO