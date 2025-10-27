CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_02
(
    @RedmineID INT,
    @ProductId INT,
    @ProductName VARCHAR(100),
    @Nickname VARCHAR(100) = 'GameBot'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
        DECLARE 
                @ServerAlias VARCHAR(100) = N'DBCUST',
                @DBName VARCHAR(100) = N'bodb_Licensee'
                ;
        SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
        DECLARE @ScriptName NVARCHAR(200) = N'Comm_{date}_{RedmineID}_{ProductName}_Step2_InitForLicenseeGroupDiscountDetail_UAT.sql';
        DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBCUST-bodb_Licensee"></info>*/
        /*
                Created: {Nickname}@{date}
                Task: UAT - Init data LicenseeGroupDiscountDetail for {ProductName} [redmine: #{RedmineID}]
                DB: DBCUST/bodb_Licensee
        */
        DECLARE @tmpProduct TABLE (ProductID INT, IsFinished BIT DEFAULT 0)
        DECLARE @ProductID INT
                
        INSERT INTO @tmpProduct        (ProductID)
        SELECT ({ProductId})
                
        WHILE(1=1)
        BEGIN
                UPDATE TOP (1) t
                SET IsFinished = 1,
                        @ProductID = ProductID
                FROM @tmpProduct t
                WHERE IsFinished = 0
                        
                IF @@ROWCOUNT = 0
                        BREAK;
                                
                --3k rows
                INSERT INTO [dbo].[LicenseeGroupDiscountDetail]
                                        ([GroupDiscountID]
                                        ,[Licenseeid]
                                        ,[Sporttype]
                                        ,[Bettype]
                                        ,[Discount])
                SELECT GroupDiscountID, gd.Licenseeid, t.Sporttype, t.Bettype, 0 as Discount
                FROM LicenseeGroupDiscount gd WITH(NOLOCK)
                        CROSS APPLY (SELECT DISTINCT l.LicenseeID, pd.Sporttype, pd.Bettype
                                                FROM CustDB.dbo.Dep_CustSuper cs WITH(NOLOCK)
                                                        INNER JOIN Licensees l WITH(NOLOCK) ON cs.site = l.LicenseeName
                                                        INNER JOIN CustDB.dbo.Dep_LicenseeProductSetting lp WITH (NOLOCK) on cs.custid = lp.CustID
                                                        INNER JOIN CustDB.dbo.Dep_ProductSetting p WITH (NOLOCK) ON p.ProductSettingID = lp.ProductSettingID
                                                        INNER JOIN CustDB.dbo.Dep_ProductSettingDetail pd WITH (NOLOCK) ON pd.ProductSettingID = p.ProductSettingID 
                                                WHERE p.SettingType = 4
                                                        AND p.ProductID = @ProductID
                                                        AND l.IsActive = 1
                                                        AND l.LicenseeID = gd.LicenseeID
                                                        AND l.licenseeName IN (''Athena000'', ''spondemo'')
                                                )t

                WAITFOR DELAY ''0:0:0.280''
        END
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