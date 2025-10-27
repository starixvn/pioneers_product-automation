CREATE OR ALTER FUNCTION dbo.f_GameBot_GenTemplate_07
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
    DECLARE @ScriptName NVARCHAR(200) = N'Comm_{date}_{RedmineID}_{ProductName}_Step7_InitForExistingCustomers_REAL.sql';
    DECLARE @ScriptContent NVARCHAR(MAX) = N'/*<info serverAlias="DBCUST-CustDB"></info>*/
        /*
                Created: {Nickname}@{date}
                Task: Init Comm Setting for {ProductName} [redmine: #{RedmineID}]
                DB: DBCUST/CustDB

                *** Not allowed to use a temporary table as input when executing SP Execrep
        */
        -- BEGIN STEP 1: DEPLOY THIS SP @DBCUST.CustDB --------
        ------------------------------------------------------        
        ALTER PROCEDURE [dbo].[Acc_Dep_DynamicCustSetting_09]
                @target VARCHAR(20),
                @mode         TINYINT, -- 1 ~ Agent, 2 ~ Member
                @CustList NVARCHAR(MAX)=''''
        AS
        BEGIN        
                SET NOCOUNT ON;
                IF (@target = ''REPLICATED'' AND @@SERVERNAME IN (''DBCUST'',''SITDBCUST'',''DBSPARE'',''DBSPARE1'',''TESTDBCUST'')) RETURN        -- run at all replicated servers
                IF (@target = ''DBCUST'' AND @@SERVERNAME NOT IN (''DBCUST'',''SITDBCUST'',''DBSPARE'',''DBSPARE1'',''TESTDBCUST'')) RETURN -- run at dbcust only

                IF (        OBJECT_ID(''Dep_CustSettingMode'') IS NULL
                        OR        OBJECT_ID(''Dep_CustDiscountGroupSetting_Member'') IS NULL        
                        OR        OBJECT_ID(''Dep_CustDiscountSetting_Member'') IS NULL                
                        )
                RETURN
                
                CREATE TABLE #tmp(CustID INT PRIMARY KEY)
                CREATE TABLE #tmpCustomers_batch ( 
                                                CustID INT, 
                                                Sporttype SMALLINT, 
                                                Bettype INT,
                                                PRIMARY KEY CLUSTERED (CustID,Sporttype,Bettype)
                                                )
                
                INSERT INTO #tmpCustomers_batch (CustID, Sporttype, Bettype)
                SELECT CustID, Sporttype, Bettype
                FROM OPENJSON(@CustList)
                        WITH
                        ( CustID                INT, 
                                Sporttype        SMALLINT, 
                                Bettype                INT
                                ) c

                IF @mode=1
                BEGIN
                        --insert group comm setting
                        INSERT INTO dbo.Dep_CustDiscountGroupSetting_Member 
                                (AgentID
                                ,Sporttype
                                ,Bettype
                                ,PlayerDiscount
                                ,AgentDiscount
                                ,MasterDiscount
                                ,SuperDiscount                
                                )
                        SELECT t.custid, t.Sporttype, t.Bettype, 0, 0, 0, 0
                        FROM #tmpCustomers_batch t        
                                LEFT JOIN Dep_CustDiscountGroupSetting_Member dcs WITH (NOLOCK) 
                                        ON dcs.AgentID = t.CustID 
                                        AND dcs.Sporttype = t.Sporttype
                                        AND dcs.Bettype = t.Bettype        
                        WHERE dcs.AgentID IS NULL
                END

                IF @mode=2
                BEGIN
                        --get: cust have not offered comm yet
                        INSERT INTO #tmp(custid)
                        SELECT DISTINCT cs.custid
                        FROM dbo.Dep_CustSettingMode cs WITH(NOLOCK)
                                        INNER JOIN #tmpCustomers_batch t ON t.CustID = cs.CustID
                                        OUTER APPLY (SELECT TOP 1 dcs_m.CustID 
                                                                FROM Dep_CustDiscountSetting_Member dcs_m WITH (NOLOCK) 
                                                                WHERE dcs_m.CustID = cs.CustID
                                                                ) AS tmp
                        WHERE ISNULL(cs.IsGroupedComm,0) = 0 AND tmp.CustID IS NULL
                        
                        -- UPDATE comm group for cust have not offered comm yet.
                        UPDATE cs
                                SET isGroupedComm = 1
                        FROM dbo.Dep_CustSettingMode cs WITH(UPDLOCK,ROWLOCK)
                                INNER JOIN #tmp cb ON cb.CustID = cs.CustID
                                OUTER APPLY (SELECT TOP 1 dcs_m.CustID FROM Dep_CustDiscountSetting_Member dcs_m WITH (NOLOCK) 
                                                                WHERE dcs_m.CustID = cs.CustID
                                                        ) AS tmp
                        WHERE ISNULL(cs.IsGroupedComm,0) = 0 AND tmp.CustID IS NULL
                        
                        -- insert private setting if already offered comm before and not belong to comm group
                        DELETE #tmp
                
                        INSERT INTO #tmp(custid)
                        SELECT DISTINCT c.CustID
                        FROM Dep_CustSettingMode c WITH (NOLOCK)
                                INNER JOIN #tmpCustomers_batch t ON c.CustID = t.CustID
                                LEFT JOIN Dep_CustDiscountSetting_Member dcs_m WITH (NOLOCK) 
                                        ON dcs_m.CustID = c.CustID 
                                        AND dcs_m.Sporttype = t.Sporttype
                                        AND dcs_m.Bettype = t.Bettype        
                        WHERE c.IsGroupedComm = 0 AND dcs_m.custid IS NULL
                
                        INSERT INTO Dep_CustDiscountSetting_Member (CustID
                                                                ,Sporttype
                                                                ,Bettype
                                                                ,PlayerDiscount
                                                                ,AgentDiscount
                                                                ,MasterDiscount
                                                                ,SuperDiscount)          
                        SELECT c.CustID, cb.Sporttype, cb.Bettype, 0,0,0,0
                        FROM Dep_CustSettingMode c WITH (NOLOCK)
                                INNER JOIN #tmp t ON t.CustID=c.CustID
                                INNER JOIN #tmpCustomers_batch cb ON t.CustID = cb.CustID
                                LEFT JOIN Dep_CustDiscountSetting_Member dcs_m WITH (NOLOCK) 
                                        ON dcs_m.CustID = c.CustID and dcs_m.Sporttype = cb.Sporttype
                                        AND dcs_m.Bettype = cb.Bettype        
                        WHERE c.IsGroupedComm = 0 AND dcs_m.custid IS NULL
                END

                DROP TABLE #tmp
        END
        GO

        -- END STEP 1: DEPLOY THIS SP @DBCUST.CustDB --------
        ------------------------------------------------------        

        ---
        ---
        -- BEGIN STEP 2: RUN THIS SCRIPT AT ALL REPLICATED SERVERS (06/DBTP) AND DBCUST (Run last)-----
        --------------------------------------------------------------------------------------
        DECLARE @max_custid INT = {max_custid}
                        , @CustList NVARCHAR(MAX)

        DECLARE @target VARCHAR(20)
        IF @@SERVERNAME IN (''DBCUST'',''SITDBCUST'',''TESTDBCUST'',''DBSPARE'',''DBSPARE1'')
                SET @target = ''DBCUST''
        ELSE 
                SET @target = ''REPLICATED''

        Print ''Server Name : '' + @target

        CREATE TABLE #Super(CustID INT)

        CREATE TABLE #SuperSportBettype (
                                                CustID INT,
                                                Sporttype SMALLINT, 
                                                Bettype INT,
                                                PRIMARY KEY CLUSTERED (CustID,Sporttype,Bettype)
                                                )

        CREATE TABLE #Agents (
                                                CustID INT, 
                                                Sporttype SMALLINT, 
                                                Bettype INT,
                                                PRIMARY KEY CLUSTERED (CustID,Sporttype,Bettype)
                                                )

        CREATE TABLE #Members (
                                                CustID INT, 
                                                Sporttype SMALLINT, 
                                                Bettype INT,
                                                PRIMARY KEY CLUSTERED (CustID,Sporttype,Bettype)
                                                )

        CREATE TABLE #Customers_batch ( 
                                                CustID INT, 
                                                Sporttype SMALLINT, 
                                                Bettype INT,
                                                PRIMARY KEY CLUSTERED (CustID,Sporttype,Bettype)
                                                )

        ---------------------------------------------------------------------------------------------
        INSERT INTO #Super(custid)
        SELECT cs.custid
        FROM dbo.Dep_CustSuper cs WITH(NOLOCK)
                INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeName = cs.site
                CROSS APPLY (SELECT TOP (1) 1 
                                        FROM dbo.Dep_LicenseeProductSetting lp WITH (NOLOCK) 
                                                        INNER JOIN dbo.Dep_ProductSetting p WITH (NOLOCK) 
                                                        ON p.ProductSettingID = lp.ProductSettingID 
                                                        AND p.SettingType = 4 
                                                        AND p.ProductID IN ({ProductId})
                                        WHERE  lp.CustID = cs.custid                                                        
                                        )
                                        AS tmp (_sb)
        WHERE  l.IsActive = 1
        AND NOT (l.licenseeName IN (''Athena000'', ''spondemo'') AND cs.currency=20)

        INSERT INTO #SuperSportBettype (CustID, Sporttype, Bettype)
        SELECT DISTINCT s.CustID, pd.Sporttype, pd.Bettype
        FROM dbo.Dep_LicenseeProductSetting lp WITH (NOLOCK) 
                INNER JOIN #Super s ON s.CustID=lp.CustID
                INNER JOIN dbo.Dep_ProductSetting p WITH (NOLOCK) ON p.ProductSettingID = lp.ProductSettingID
                INNER JOIN dbo.Dep_ProductSettingDetail pd WITH (NOLOCK) ON pd.ProductSettingID = p.ProductSettingID 
        WHERE p.SettingType = 4
                AND p.ProductID IN ({ProductId})

        --Agents
        INSERT INTO #Agents (CustID, Sporttype, Bettype)
        SELECT c.custid, s.Sporttype, s.Bettype
        FROM dbo.CustInfo c WITH(NOLOCK)
        INNER JOIN #SuperSportBettype s ON s.CustID=c.srecommend
        WHERE mrecommend NOT IN (SELECT custid 
                                                        FROM dbo.custinfo ci WITH(NOLOCK)
                                                        WHERE ci.srecommend=c.srecommend 
                                                                AND (username LIKE ''%Acc%'' OR username LIKE ''%LocalBank%'' OR username LIKE ''%AFF%'' OR username LIKE ''AB88''+''CAS%'' )
                                                                AND roleid=3
                                                        )
                AND c.custid <= @max_custid
                AND c.roleid=2

        --Members
        INSERT INTO #Members (CustID, Sporttype, Bettype)
        SELECT c.custid, s.Sporttype, s.Bettype
        FROM dbo.CustInfo c WITH(NOLOCK)
        INNER JOIN #SuperSportBettype s ON s.CustID=c.srecommend
        WHERE mrecommend NOT IN (SELECT custid 
                                                        FROM dbo.custinfo ci WITH(NOLOCK)
                                                        WHERE ci.srecommend=c.srecommend 
                                                                AND (username LIKE ''%Acc%'' OR username LIKE ''%LocalBank%'' OR username LIKE ''%AFF%'' OR username LIKE ''AB88''+''CAS%'' )
                                                                AND roleid=3
                                                        )
                AND (c.username not like ''%ClearBal'' and c.username not like ''%CashOut'' and c.username not like ''%OddsAdj'' and c.username not like ''%OddsBoostAdj'')
                AND c.custid <= @max_custid
                AND c.roleid=1
        ---------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        DECLARE @Cust_cnt INT

        SELECT @Cust_cnt = COUNT(1)
        FROM #Agents

        SELECT @Cust_cnt += COUNT(1)
        FROM #Members

        DECLARE @msg_total NVARCHAR(200) = ''Total of Customers Affected: %d.''

        RAISERROR (@msg_total, 0, 1, @Cust_cnt) WITH NOWAIT

        --Update for Agent
        WHILE (1 = 1)
        BEGIN
                DELETE FROM #Customers_batch

                DELETE TOP (3000) T
                OUTPUT deleted.CustID, deleted.Sporttype, deleted.Bettype
                        INTO #Customers_batch(CustID,Sporttype, Bettype)
                FROM #Agents t 

                IF @@ROWCOUNT = 0 BREAK

                SELECT @CustList = (SELECT CustID, Sporttype, Bettype
                                                        FROM #Customers_batch
                                                        FOR JSON AUTO
                                                );

                EXEC dbo.[Acc_Dep_DynamicCustSetting_09] 
                                        @target = @target,
                                        @mode = 1,
                                        @CustList=@CustList
                
                WAITFOR DELAY ''00:00:0.050''

                SET @msg_total = ''Agent - Curdt: '' + CONVERT(VARCHAR(50), GETDATE(), 121)

                RAISERROR (@msg_total, 0, 1) WITH NOWAIT
        END                        
                
        --Update for Member
        WHILE (1 = 1)
        BEGIN
                DELETE FROM #Customers_batch

                DELETE TOP (3000) T
                OUTPUT deleted.CustID, deleted.Sporttype, deleted.Bettype
                        INTO #Customers_batch(CustID,Sporttype, Bettype)
                FROM #Members t 

                IF @@ROWCOUNT = 0 BREAK
                
                SELECT @CustList = (SELECT CustID, Sporttype, Bettype
                                                        FROM #Customers_batch
                                                        FOR JSON AUTO
                                                );

                EXEC dbo.[Acc_Dep_DynamicCustSetting_09] 
                                        @target = @target,
                                        @mode = 2,
                                        @CustList=@CustList
                
                WAITFOR DELAY ''00:00:0.050''

                SET @msg_total = ''Member - Curdt: '' + CONVERT(VARCHAR(50), GETDATE(), 121)

                RAISERROR (@msg_total, 0, 1) WITH NOWAIT
        END                

        DROP TABLE #Agents, #Members, #Customers_batch, #Super, #SuperSportBettype
        GO
        -- END STEP 2: RUN THIS SCRIPT AT ALL REPLICATED SERVERS (/06/DBTP) AND DBCUST (Run last) -----
        -----------------------------------------------------------------------------------   
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
        SELECT @ServerAlias AS ServerAlias,
                @DBName AS DBName,
                ScriptName, ScriptContent
            FROM (
                    VALUES(@ScriptName, @ScriptContent)
            )  AS t (ScriptName, ScriptContent)
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    ) AS NVARCHAR(MAX));
END