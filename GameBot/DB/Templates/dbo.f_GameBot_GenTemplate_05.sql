CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_05
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
                @DBName VARCHAR(100) = N'CustDB'
                ;
        SELECT @ProductName = REPLACE(ISNULL(@ProductName, ''), ' ', '');
        DECLARE @ScriptName NVARCHAR(200) = N'Comm_{date}_{RedmineID}_{ProductName}_Step5_InitForLicenseeProductSetting_REAL.sql';
        DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBCUST-CustDB"></info>*/
        /*
                Created: {Nickname}@{date}
                Task: UAT - Add product setting for Licensees [redmine: #{RedmineID}]
                DB: DBCUST-CustDB
        */
        ---------------------------------------------------------------------------------
        --Dep_LicenseeProductSetting
        USE CustDB
        GO

        INSERT INTO dbo.Dep_LicenseeProductSetting(CustID,ProductSettingID,RepUpdateTime)
        SELECT s.custid, t.ProductSettingID, SYSDATETIME()
        FROM dbo.Dep_CustSuper s WITH(NOLOCK)
                INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeName = s.site
                CROSS APPLY (SELECT ProductSettingID, ProductID
                                        FROM Dep_ProductSetting WITH (NOLOCK)
                                        WHERE SettingType=9 AND ProductID IN ({ProductId})
                                        ) t
                CROSS APPLY (SELECT TOP 1 lp.CustID 
                                        FROM Dep_LicenseeProductSetting lp WITH (NOLOCK) 
                                                INNER JOIN Dep_ProductSetting pd WITH (NOLOCK) ON pd.ProductSettingID = lp.ProductSettingID
                                        WHERE lp.CustID = s.custid AND pd.SettingType = 4
                                                AND pd.ProductID = t.ProductID
                                        ) AS p_tmp
                LEFT JOIN Dep_LicenseeProductSetting p WITH(NOLOCK) 
                        ON p.custid = s.custid
                        AND p.ProductSettingID = t.ProductSettingID
        WHERE p.custid IS NULL                
        AND l.IsActive = 1
        AND (l.licenseeName IN (''Athena000'', ''spondemo'') AND s.currency=20)
        ';

        SELECT @ScriptContent = REPLACE(@ScriptContent, '{RedmineID}', CAST(@RedmineID AS VARCHAR(10))),
                @ScriptName = REPLACE(@ScriptName, '{RedmineID}', CAST(@RedmineID AS VARCHAR(10)));
        SELECT @ScriptContent = REPLACE(@ScriptContent, '{ProductId}', CAST(@ProductId AS VARCHAR(10))),
                @ScriptName = REPLACE(@ScriptName, '{ProductId}',  CAST(@ProductId AS VARCHAR(10)));
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