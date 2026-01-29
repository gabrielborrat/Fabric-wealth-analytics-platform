CREATE OR ALTER   PROCEDURE dbo.sp_ctl_fact_transactions_duplicates_transaction_id
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId,
        @JobId,
        @StartTs,
        @ExecDate,
        @TxnMonth,
        'STARTED',
        'DQ: duplicates transaction_id in fact_transactions'
    );

    BEGIN TRY
        -- rows_source = nb de lignes fact dans le scope
        SELECT @RowsSource = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE (@TxnMonth IS NULL OR txn_month = @TxnMonth);

        -- issue_count = nb de transaction_id qui apparaissent plus d'une fois
        SELECT @IssueCount = COUNT_BIG(*)
        FROM (
            SELECT f.transaction_id
            FROM dbo.fact_transactions f
            WHERE (@TxnMonth IS NULL OR f.txn_month = @TxnMonth)
            GROUP BY f.transaction_id
            HAVING COUNT_BIG(*) > 1
        ) d;

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId,
            'duplicates_transaction_id',
            SYSUTCDATETIME(),
            @ExecDate,
            @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            'fact_transactions has duplicate transaction_id values (scope: month if provided)'
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS',
            @RowsSource,
            CONCAT('DQ completed. duplicate_transaction_id_count=', @IssueCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED',
            @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_ctl_fact_transactions_empty_record_hash
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';
    
    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId,
        @JobId,
        @StartTs,
        @ExecDate,
        @TxnMonth,
        'STARTED',
        'DQ: empty/blank record_hash in fact_transactions'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE (@TxnMonth IS NULL OR txn_month = @TxnMonth);

        SELECT @IssueCount = COUNT_BIG(*)
        FROM dbo.fact_transactions f
        WHERE (@TxnMonth IS NULL OR f.txn_month = @TxnMonth)
          AND (
                f.record_hash IS NULL
                OR LTRIM(RTRIM(f.record_hash)) = ''
              );

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId,
            'empty_record_hash',
            SYSUTCDATETIME(),
            @ExecDate,
            @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            'fact_transactions has empty/blank record_hash values (NOT NULL but can be blank)'
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS',
            @RowsSource,
            CONCAT('DQ completed. empty_record_hash_row_count=', @IssueCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED',
            @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;

CREATE OR ALTER   PROCEDURE dbo.sp_ctl_fact_transactions_orphans_card
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'DQ: orphans card_key in fact_transactions'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE (@TxnMonth IS NULL OR txn_month = @TxnMonth);

        SELECT @IssueCount = COUNT_BIG(*)
        FROM dbo.fact_transactions f
        LEFT JOIN dbo.dim_card c
          ON c.card_key = f.card_key
        WHERE c.card_key IS NULL
          AND (@TxnMonth IS NULL OR f.txn_month = @TxnMonth);

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'orphans_card_key', SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            'fact_transactions rows with card_key not found in dim_card'
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', @RowsSource,
            CONCAT('DQ completed. issue_count=', @IssueCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_ctl_fact_transactions_orphans_date
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'DQ: orphans date_key in fact_transactions'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE (@TxnMonth IS NULL OR txn_month = @TxnMonth);

        SELECT @IssueCount = COUNT_BIG(*)
        FROM dbo.fact_transactions f
        LEFT JOIN dbo.dim_date d
          ON d.date_key = f.date_key
        WHERE d.date_key IS NULL
          AND (@TxnMonth IS NULL OR f.txn_month = @TxnMonth);

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'orphans_date_key', SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            'fact_transactions rows with date_key not found in dim_date'
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', @RowsSource,
            CONCAT('DQ completed. issue_count=', @IssueCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_ctl_fact_transactions_orphans_mcc
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'DQ: orphans mcc_key in fact_transactions'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE (@TxnMonth IS NULL OR txn_month = @TxnMonth);

        SELECT @IssueCount = COUNT_BIG(*)
        FROM dbo.fact_transactions f
        LEFT JOIN dbo.dim_mcc m
          ON m.mcc_key = f.mcc_key
        WHERE m.mcc_key IS NULL
          AND (@TxnMonth IS NULL OR f.txn_month = @TxnMonth);

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'orphans_mcc_key', SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            'fact_transactions rows with mcc_key not found in dim_mcc'
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', @RowsSource,
            CONCAT('DQ completed. issue_count=', @IssueCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;

CREATE OR ALTER   PROCEDURE dbo.sp_ctl_fact_transactions_orphans_user
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'DQ: orphans user_key in fact_transactions'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE (@TxnMonth IS NULL OR txn_month = @TxnMonth);

        SELECT @IssueCount = COUNT_BIG(*)
        FROM dbo.fact_transactions f
        LEFT JOIN dbo.dim_user u
          ON u.user_key = f.user_key
        WHERE u.user_key IS NULL
          AND (@TxnMonth IS NULL OR f.txn_month = @TxnMonth);

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'orphans_user_key', SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            'fact_transactions rows with user_key not found in dim_user'
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', @RowsSource,
            CONCAT('DQ completed. issue_count=', @IssueCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_ctl_recon_gold_vs_dwh_amounts
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @GoldSum    DECIMAL(38,6) = 0;
    DECLARE @DwhSum     DECIMAL(38,6) = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @TxnMonth IS NULL
        THROW 50001, 'TxnMonth is required (expected first day of month).', 1;

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'DQ recon: amounts Gold vs DWH (fact_transactions)'
    );

    BEGIN TRY
        SELECT @GoldSum = CAST(ISNULL(SUM(CAST(amount AS DECIMAL(38,6))), 0) AS DECIMAL(38,6))
        FROM lh_wm_core.dbo.gold_fact_transactions
        WHERE txn_month = @TxnMonth;

        SELECT @DwhSum = CAST(ISNULL(SUM(CAST(amount AS DECIMAL(38,6))), 0) AS DECIMAL(38,6))
        FROM dbo.fact_transactions
        WHERE txn_month = @TxnMonth;

        SELECT @RowsSource = COUNT_BIG(*)
        FROM lh_wm_core.dbo.gold_fact_transactions
        WHERE txn_month = @TxnMonth;

        SET @IssueCount = CASE WHEN @GoldSum = @DwhSum THEN 0 ELSE 1 END;

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'recon_amounts_gold_vs_dwh', SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            CONCAT('GoldSum=', @GoldSum, '; DwhSum=', @DwhSum)
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', @RowsSource,
            CONCAT('Recon completed. GoldSum=', @GoldSum, '; DwhSum=', @DwhSum)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_ctl_recon_gold_vs_dwh_counts
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource BIGINT = 0;
    DECLARE @GoldCount  BIGINT = 0;
    DECLARE @DwhCount   BIGINT = 0;
    DECLARE @IssueCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';
    
    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @TxnMonth IS NULL
        THROW 50001, 'TxnMonth is required (expected first day of month).', 1;

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'DQ recon: counts Gold vs DWH (fact_transactions)'
    );

    BEGIN TRY
        SELECT @GoldCount = COUNT_BIG(*)
        FROM lh_wm_core.dbo.gold_fact_transactions
        WHERE txn_month = @TxnMonth;

        SELECT @DwhCount = COUNT_BIG(*)
        FROM dbo.fact_transactions
        WHERE txn_month = @TxnMonth;

        SET @RowsSource = @GoldCount;
        SET @IssueCount = CASE WHEN @GoldCount = @DwhCount THEN 0 ELSE 1 END;

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'recon_counts_gold_vs_dwh', SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @IssueCount = 0 THEN 'PASS' ELSE 'FAIL' END,
            @IssueCount,
            CONCAT('GoldCount=', @GoldCount, '; DwhCount=', @DwhCount)
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', @RowsSource,
            CONCAT('Recon completed. GoldCount=', @GoldCount, '; DwhCount=', @DwhCount)
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', @RowsSource,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;



CREATE OR ALTER   PROCEDURE dbo.sp_job_dim_card_refresh
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource   BIGINT = 0;
    DECLARE @RowsInserted BIGINT = 0;
    DECLARE @RowsUpdated  BIGINT = 0;
    DECLARE @RowsDeleted  BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    INSERT INTO dbo.wh_job_run_log(run_id, job_id, exec_ts_start, exec_date, status, message)
    VALUES (@RunId, @JobId, @StartTs, @ExecDate, 'STARTED', 'SCD0 upsert dim_card');

    BEGIN TRY
        SELECT @RowsSource = COUNT(*)
        FROM lh_wm_core.dbo.gold_dim_card;

        SELECT @RowsUpdated = COUNT(*)
        FROM dbo.dim_card t
        JOIN lh_wm_core.dbo.gold_dim_card s
          ON t.card_id = CONVERT(VARCHAR(64), s.card_id)
        WHERE ISNULL(t.record_hash,'') <> ISNULL(CONVERT(VARCHAR(64), s.record_hash),'');

        -- INSERT new
        INSERT INTO dbo.dim_card (
            card_id, client_id, card_brand, card_type, has_chip,
            credit_limit, num_cards_issued, card_on_dark_web, record_hash
        )
        SELECT
            CONVERT(VARCHAR(64), s.card_id)          AS card_id,
            CONVERT(VARCHAR(64), s.client_id)        AS client_id,
            CONVERT(VARCHAR(50), s.card_brand)       AS card_brand,
            CONVERT(VARCHAR(50), s.card_type)        AS card_type,
            CAST(s.has_chip AS BIT)                  AS has_chip,
            s.credit_limit,
            s.num_cards_issued,
            CAST(s.card_on_dark_web AS BIT)          AS card_on_dark_web,
            CONVERT(VARCHAR(64), s.record_hash)      AS record_hash
        FROM lh_wm_core.dbo.gold_dim_card s
        LEFT JOIN dbo.dim_card t
          ON t.card_id = CONVERT(VARCHAR(64), s.card_id)
        WHERE t.card_id IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        -- UPDATE changed only
        UPDATE t
           SET
             t.client_id        = CONVERT(VARCHAR(64), s.client_id),
             t.card_brand       = CONVERT(VARCHAR(50), s.card_brand),
             t.card_type        = CONVERT(VARCHAR(50), s.card_type),
             t.has_chip         = CAST(s.has_chip AS BIT),
             t.credit_limit     = s.credit_limit,
             t.num_cards_issued = s.num_cards_issued,
             t.card_on_dark_web = CAST(s.card_on_dark_web AS BIT),
             t.record_hash      = CONVERT(VARCHAR(64), s.record_hash)
        FROM dbo.dim_card t
        JOIN lh_wm_core.dbo.gold_dim_card s
          ON t.card_id = CONVERT(VARCHAR(64), s.card_id)
        WHERE ISNULL(t.record_hash,'') <> ISNULL(CONVERT(VARCHAR(64), s.record_hash),'');

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log(
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'SUCCESS', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'SCD0 upsert dim_card completed'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log(
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'FAILED', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_job_dim_date_refresh
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,  
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource   BIGINT = 0;
    DECLARE @RowsInserted BIGINT = 0;
    DECLARE @RowsUpdated  BIGINT = 0;
    DECLARE @RowsDeleted  BIGINT = 0;  -- SCD0 -> normalement 0

    -- Defaults
    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    -- LOG START (append-only)
    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, 'STARTED', 'Load dim_date (SCD0)'
    );

    BEGIN TRY
        ------------------------------------------------------------------
        -- 1) rows_source
        ------------------------------------------------------------------
        SELECT @RowsSource = COUNT_BIG(*)
        FROM lh_wm_core.dbo.gold_dim_date;

        ------------------------------------------------------------------
        -- 2) INSERT missing (new dates)
        --    Align columns + compute record_hash in DWH
        ------------------------------------------------------------------
        INSERT INTO dbo.dim_date (
            date_id,
            full_date,
            [year],
            [quarter],
            [month],
            [week],
            day_of_week,
            is_weekend,
            is_business_day,
            record_hash
        )
        SELECT
            CAST(s.date_id AS INT)                AS date_id,
            CAST(s.date_value AS DATE)            AS full_date,
            CAST(s.year_number AS INT)            AS [year],
            CAST(s.quarter_number AS INT)         AS [quarter],
            CAST(s.month_number AS INT)           AS [month],
            CAST(s.week_of_year AS INT)           AS [week],
            CAST(s.day_of_week_iso AS INT)        AS day_of_week,
            CAST(s.is_weekend AS BIT)             AS is_weekend,
            CAST(CASE WHEN CAST(s.is_weekend AS BIT) = 1 THEN 0 ELSE 1 END AS BIT) AS is_business_day,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONCAT(
                CAST(s.date_id AS VARCHAR(16)), '|',
                CONVERT(VARCHAR(10), CAST(s.date_value AS DATE), 23), '|',
                COALESCE(CAST(s.year_number AS VARCHAR(10)), ''), '|',
                COALESCE(CAST(s.quarter_number AS VARCHAR(10)), ''), '|',
                COALESCE(CAST(s.month_number AS VARCHAR(10)), ''), '|',
                COALESCE(CAST(s.week_of_year AS VARCHAR(10)), ''), '|',
                COALESCE(CAST(s.day_of_week_iso AS VARCHAR(10)), ''), '|',
                CAST(CAST(s.is_weekend AS BIT) AS VARCHAR(1))
            )), 2) AS record_hash
        FROM lh_wm_core.dbo.gold_dim_date s
        LEFT JOIN dbo.dim_date t
            ON t.date_id = CAST(s.date_id AS INT)
        WHERE t.date_id IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        ------------------------------------------------------------------
        -- 3) UPDATE changed only (SCD0 overwrite)
        --    Update when computed hash differs from stored record_hash
        ------------------------------------------------------------------
        ;WITH src AS (
            SELECT
                CAST(s.date_id AS INT)                AS date_id,
                CAST(s.date_value AS DATE)            AS full_date,
                CAST(s.year_number AS INT)            AS [year],
                CAST(s.quarter_number AS INT)         AS [quarter],
                CAST(s.month_number AS INT)           AS [month],
                CAST(s.week_of_year AS INT)           AS [week],
                CAST(s.day_of_week_iso AS INT)        AS day_of_week,
                CAST(s.is_weekend AS BIT)             AS is_weekend,
                CAST(CASE WHEN CAST(s.is_weekend AS BIT) = 1 THEN 0 ELSE 1 END AS BIT) AS is_business_day,
                CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CONCAT(
                    CAST(s.date_id AS VARCHAR(16)), '|',
                    CONVERT(VARCHAR(10), CAST(s.date_value AS DATE), 23), '|',
                    COALESCE(CAST(s.year_number AS VARCHAR(10)), ''), '|',
                    COALESCE(CAST(s.quarter_number AS VARCHAR(10)), ''), '|',
                    COALESCE(CAST(s.month_number AS VARCHAR(10)), ''), '|',
                    COALESCE(CAST(s.week_of_year AS VARCHAR(10)), ''), '|',
                    COALESCE(CAST(s.day_of_week_iso AS VARCHAR(10)), ''), '|',
                    CAST(CAST(s.is_weekend AS BIT) AS VARCHAR(1))
                )), 2) AS record_hash
            FROM lh_wm_core.dbo.gold_dim_date s
        )
        UPDATE t
            SET
                t.full_date       = s.full_date,
                t.[year]          = s.[year],
                t.[quarter]       = s.[quarter],
                t.[month]         = s.[month],
                t.[week]          = s.[week],
                t.day_of_week     = s.day_of_week,
                t.is_weekend      = s.is_weekend,
                t.is_business_day = s.is_business_day,
                t.record_hash     = s.record_hash
        FROM dbo.dim_date t
        JOIN src s
            ON t.date_id = s.date_id
        WHERE ISNULL(t.record_hash, '') <> s.record_hash;

        SET @RowsUpdated = @@ROWCOUNT;

        ------------------------------------------------------------------
        -- LOG SUCCESS (append-only) + metrics
        ------------------------------------------------------------------
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'SUCCESS', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'dim_date loaded (SCD0)'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'FAILED', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;

CREATE OR ALTER   PROCEDURE dbo.sp_job_dim_mcc_refresh
    @RunId    VARCHAR(64) = NULL,
    @JobId      VARCHAR(64) = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource   BIGINT = 0;
    DECLARE @RowsInserted BIGINT = 0;
    DECLARE @RowsUpdated  BIGINT = 0;
    DECLARE @RowsDeleted  BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';    

    INSERT INTO dbo.wh_job_run_log(run_id, job_id, exec_ts_start, exec_date, status, message)
    VALUES (@RunId, @JobId, @StartTs, @ExecDate, 'STARTED', 'SCD0 upsert dim_mcc');

    BEGIN TRY
        SELECT @RowsSource = COUNT(*)
        FROM lh_wm_core.dbo.gold_dim_mcc;

        SELECT @RowsUpdated = COUNT(*)
        FROM dbo.dim_mcc t
        JOIN lh_wm_core.dbo.gold_dim_mcc s
          ON t.mcc_code = CAST(s.mcc_code AS INT)
        WHERE ISNULL(t.record_hash,'') <> ISNULL(CONVERT(VARCHAR(64), s.record_hash),'');

        -- INSERT new
        INSERT INTO dbo.dim_mcc (mcc_code, mcc_description, mcc_category, record_hash)
        SELECT
            CAST(s.mcc_code AS INT)               AS mcc_code,
            CONVERT(VARCHAR(200), s.mcc_description) AS mcc_description,
            NULL                                  AS mcc_category,
            CONVERT(VARCHAR(64), s.record_hash)   AS record_hash
        FROM lh_wm_core.dbo.gold_dim_mcc s
        LEFT JOIN dbo.dim_mcc t
          ON t.mcc_code = CAST(s.mcc_code AS INT)
        WHERE t.mcc_code IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        -- UPDATE changed only
        UPDATE t
           SET
             t.mcc_description = CONVERT(VARCHAR(200), s.mcc_description),
             t.record_hash     = CONVERT(VARCHAR(64), s.record_hash)
        FROM dbo.dim_mcc t
        JOIN lh_wm_core.dbo.gold_dim_mcc s
          ON t.mcc_code = CAST(s.mcc_code AS INT)
        WHERE ISNULL(t.record_hash,'') <> ISNULL(CONVERT(VARCHAR(64), s.record_hash),'');

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log(
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'SUCCESS', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'SCD0 upsert dim_mcc completed'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log(
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'FAILED', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;

CREATE OR ALTER   PROCEDURE dbo.sp_job_dim_month_refresh
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource   BIGINT = 0;
    DECLARE @RowsInserted BIGINT = 0;
    DECLARE @RowsUpdated  BIGINT = 0;
    DECLARE @RowsDeleted  BIGINT = 0;  -- SCD0 -> toujours 0

    ------------------------------------------------------------------
    -- Defaults (pattern DWH)
    ------------------------------------------------------------------
    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';
    ------------------------------------------------------------------
    -- LOG START (append-only)
    ------------------------------------------------------------------
    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, status, message
    )
    VALUES (
        @RunId,
        @JobId,
        @StartTs,
        @ExecDate,
        'STARTED',
        'Load dim_month (SCD0)'
    );

    BEGIN TRY
        ------------------------------------------------------------------
        -- 0) Ensure target table exists (optional safeguard) - NO PK
        ------------------------------------------------------------------
        IF OBJECT_ID('dbo.dim_month', 'U') IS NULL
        BEGIN
            CREATE TABLE dbo.dim_month (
                month_start  DATE        NOT NULL,   -- YYYY-MM-01
                [year]       INT         NOT NULL,
                [month]      INT         NOT NULL,   -- 1..12
                yyyymm       INT         NOT NULL,   -- YYYYMM
                month_label  VARCHAR(7)  NOT NULL    -- 'YYYY-MM'
            );
        END;

        ------------------------------------------------------------------
        -- 1) rows_source (source = Gold dim_date)
        ------------------------------------------------------------------
        SELECT @RowsSource = COUNT_BIG(*)
        FROM (
            SELECT
                CAST(s.year_number AS INT)  AS [year],
                CAST(s.month_number AS INT) AS [month]
            FROM lh_wm_core.dbo.gold_dim_date s
            GROUP BY
                CAST(s.year_number AS INT),
                CAST(s.month_number AS INT)
        ) src;

        ------------------------------------------------------------------
        -- 2) INSERT missing months
        ------------------------------------------------------------------
        INSERT INTO dbo.dim_month (
            month_start,
            [year],
            [month],
            yyyymm,
            month_label
        )
        SELECT
            DATEFROMPARTS(src.[year], src.[month], 1)                           AS month_start,
            src.[year],
            src.[month],
            src.[year] * 100 + src.[month]                                      AS yyyymm,
            CONCAT(
                CAST(src.[year] AS VARCHAR(4)),
                '-',
                RIGHT(CONCAT('0', CAST(src.[month] AS VARCHAR(2))), 2)
            ) AS month_label
        FROM (
            SELECT
                CAST(s.year_number AS INT)  AS [year],
                CAST(s.month_number AS INT) AS [month]
            FROM lh_wm_core.dbo.gold_dim_date s
            GROUP BY
                CAST(s.year_number AS INT),
                CAST(s.month_number AS INT)
        ) src
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.dim_month t
            WHERE t.month_start = DATEFROMPARTS(src.[year], src.[month], 1)
        );

        SET @RowsInserted = @@ROWCOUNT;

        ------------------------------------------------------------------
        -- 3) UPDATE changed months (SCD0 overwrite)
        ------------------------------------------------------------------
        ;WITH src AS (
            SELECT
                CAST(s.year_number AS INT)  AS [year],
                CAST(s.month_number AS INT) AS [month]
            FROM lh_wm_core.dbo.gold_dim_date s
            GROUP BY
                CAST(s.year_number AS INT),
                CAST(s.month_number AS INT)
        )
        UPDATE t
            SET
                t.[year]       = s.[year],
                t.[month]      = s.[month],
                t.yyyymm       = s.[year] * 100 + s.[month],
                t.month_label  = CONCAT(
                                    CAST(s.[year] AS VARCHAR(4)),
                                    '-',
                                    RIGHT(CONCAT('0', CAST(s.[month] AS VARCHAR(2))), 2)
                                 )
        FROM dbo.dim_month t
        JOIN src s
            ON t.month_start = DATEFROMPARTS(s.[year], s.[month], 1)
        WHERE
            t.[year] <> s.[year]
            OR t.[month] <> s.[month]
            OR t.yyyymm <> (s.[year] * 100 + s.[month])
            OR t.month_label <> CONCAT(
                                    CAST(s.[year] AS VARCHAR(4)),
                                    '-',
                                    RIGHT(CONCAT('0', CAST(s.[month] AS VARCHAR(2))), 2)
                               );

        SET @RowsUpdated = @@ROWCOUNT;

        ------------------------------------------------------------------
        -- LOG SUCCESS (append-only)
        ------------------------------------------------------------------
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs,
            @EndTs,
            @ExecDate,
            'SUCCESS',
            @RowsSource,
            @RowsInserted,
            @RowsUpdated,
            @RowsDeleted,
            'dim_month loaded (SCD0)'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs,
            @EndTs,
            @ExecDate,
            'FAILED',
            @RowsSource,
            @RowsInserted,
            @RowsUpdated,
            @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;

CREATE OR ALTER   PROCEDURE dbo.sp_job_dim_user_refresh
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource   BIGINT = 0;
    DECLARE @RowsInserted BIGINT = 0;
    DECLARE @RowsUpdated  BIGINT = 0;
    DECLARE @RowsDeleted  BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    INSERT INTO dbo.wh_job_run_log(run_id, job_id, exec_ts_start, exec_date, status, message)
    VALUES (@RunId, @JobId, @StartTs, @ExecDate, 'STARTED', 'SCD0 upsert dim_user');

    BEGIN TRY
        SELECT @RowsSource = COUNT(*)
        FROM lh_wm_core.dbo.gold_dim_user;

        -- rows_updated (before update)
        SELECT @RowsUpdated = COUNT(*)
        FROM dbo.dim_user t
        JOIN lh_wm_core.dbo.gold_dim_user s
          ON t.client_id = CONVERT(VARCHAR(64), s.client_id)
        WHERE ISNULL(t.record_hash,'') <> ISNULL(CONVERT(VARCHAR(64), s.record_hash),'');

        -- INSERT new
        INSERT INTO dbo.dim_user (client_id, current_age, yearly_income, total_debt, credit_score, address, record_hash)
        SELECT
            CONVERT(VARCHAR(64), s.client_id)       AS client_id,
            s.current_age,
            s.yearly_income,
            s.total_debt,
            s.credit_score,
            CONVERT(VARCHAR(500), s.address)        AS address,
            CONVERT(VARCHAR(64), s.record_hash)     AS record_hash
        FROM lh_wm_core.dbo.gold_dim_user s
        LEFT JOIN dbo.dim_user t
          ON t.client_id = CONVERT(VARCHAR(64), s.client_id)
        WHERE t.client_id IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        -- UPDATE changed only
        UPDATE t
           SET
             t.current_age   = s.current_age,
             t.yearly_income = s.yearly_income,
             t.total_debt    = s.total_debt,
             t.credit_score  = s.credit_score,
             t.address       = CONVERT(VARCHAR(500), s.address),
             t.record_hash   = CONVERT(VARCHAR(64), s.record_hash)
        FROM dbo.dim_user t
        JOIN lh_wm_core.dbo.gold_dim_user s
          ON t.client_id = CONVERT(VARCHAR(64), s.client_id)
        WHERE ISNULL(t.record_hash,'') <> ISNULL(CONVERT(VARCHAR(64), s.record_hash),'');

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log(
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'SUCCESS', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'SCD0 upsert dim_user completed'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log(
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate,
            'FAILED', @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;

CREATE OR ALTER   PROCEDURE dbo.sp_job_fact_transactions_daily_refresh_month
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource    BIGINT = 0;
    DECLARE @RowsInserted  BIGINT = 0;
    DECLARE @RowsUpdated   BIGINT = 0;
    DECLARE @RowsDeleted   BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL 
        SET @JobId = 'UNKNOWN';
    
    IF @TxnMonth IS NULL
        THROW 50001, 'TxnMonth is required (expected first day of month).', 1;

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId,
        @JobId,
        @StartTs,
        @ExecDate,
        @TxnMonth,
        'STARTED',
        'UPSERT fact_transactions_daily monthly slice'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM (
            SELECT
                ft.date_key, ft.user_key, ft.card_key, ft.mcc_key, ft.currency
            FROM dbo.fact_transactions ft
            WHERE ft.txn_month = @TxnMonth
            GROUP BY
                ft.date_key, ft.user_key, ft.card_key, ft.mcc_key, ft.currency
        ) g;

        ;WITH src AS (
            SELECT
                ft.date_key,
                ft.user_key,
                ft.card_key,
                ft.mcc_key,
                ft.currency,
                CAST(ft.txn_date  AS DATE) AS txn_date,
                CAST(ft.txn_month AS DATE) AS txn_month,

                COUNT_BIG(1) AS txn_count_total,
                SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END) AS txn_count_success,
                SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END) AS txn_count_failed,
                SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END) AS txn_count_unknown,

                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)) AS amount_sum_total,
                CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_success,
                CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_failed,
                CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_unknown,
                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)) AS amount_abs_sum_total,

                CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)) AS amount_avg_success,
                CAST(MIN(ft.amount) AS DECIMAL(18,2)) AS amount_min,
                CAST(MAX(ft.amount) AS DECIMAL(18,2)) AS amount_max,

                SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END) AS txn_count_chip_used,
                CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_chip_used,

                MAX(ft.gold_load_ts) AS gold_load_ts_max,

                CONVERT(VARCHAR(64),
                    HASHBYTES('SHA2_256', CONCAT(
                        COUNT_BIG(1), '|',
                        SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)), '|',
                        CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(MIN(ft.amount) AS DECIMAL(18,2)), '|',
                        CAST(MAX(ft.amount) AS DECIMAL(18,2)), '|',
                        SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2))
                    )),
                2) AS aggregate_hash
            FROM dbo.fact_transactions ft
            WHERE ft.txn_month = @TxnMonth
            GROUP BY
                ft.date_key, ft.user_key, ft.card_key, ft.mcc_key, ft.currency,
                CAST(ft.txn_date AS DATE), CAST(ft.txn_month AS DATE)
        )
        UPDATE t
           SET
               t.txn_count_total       = s.txn_count_total,
               t.txn_count_success     = s.txn_count_success,
               t.txn_count_failed      = s.txn_count_failed,
               t.txn_count_unknown     = s.txn_count_unknown,
               t.amount_sum_total      = s.amount_sum_total,
               t.amount_sum_success    = s.amount_sum_success,
               t.amount_sum_failed     = s.amount_sum_failed,
               t.amount_sum_unknown    = s.amount_sum_unknown,
               t.amount_abs_sum_total  = s.amount_abs_sum_total,
               t.amount_avg_success    = s.amount_avg_success,
               t.amount_min            = s.amount_min,
               t.amount_max            = s.amount_max,
               t.txn_count_chip_used   = s.txn_count_chip_used,
               t.amount_sum_chip_used  = s.amount_sum_chip_used,
               t.gold_load_ts_max      = s.gold_load_ts_max,
               t.aggregate_hash        = s.aggregate_hash,
               t.run_id_last           = @RunId
        FROM dbo.fact_transactions_daily t
        JOIN src s
          ON s.date_key  = t.date_key
         AND s.user_key  = t.user_key
         AND s.card_key  = t.card_key
         AND s.mcc_key   = t.mcc_key
         AND s.currency  = t.currency
         AND t.txn_month = @TxnMonth
        WHERE ISNULL(t.aggregate_hash,'') <> s.aggregate_hash;

        SET @RowsUpdated = @@ROWCOUNT;

        ;WITH src AS (
            SELECT
                ft.date_key,
                ft.user_key,
                ft.card_key,
                ft.mcc_key,
                ft.currency,
                CAST(ft.txn_date  AS DATE) AS txn_date,
                CAST(ft.txn_month AS DATE) AS txn_month,

                COUNT_BIG(1) AS txn_count_total,
                SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END) AS txn_count_success,
                SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END) AS txn_count_failed,
                SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END) AS txn_count_unknown,

                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)) AS amount_sum_total,
                CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_success,
                CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_failed,
                CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_unknown,
                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)) AS amount_abs_sum_total,

                CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)) AS amount_avg_success,
                CAST(MIN(ft.amount) AS DECIMAL(18,2)) AS amount_min,
                CAST(MAX(ft.amount) AS DECIMAL(18,2)) AS amount_max,

                SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END) AS txn_count_chip_used,
                CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_chip_used,

                MAX(ft.gold_load_ts) AS gold_load_ts_max,

                CONVERT(VARCHAR(64),
                    HASHBYTES('SHA2_256', CONCAT(
                        COUNT_BIG(1), '|',
                        SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)), '|',
                        CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(MIN(ft.amount) AS DECIMAL(18,2)), '|',
                        CAST(MAX(ft.amount) AS DECIMAL(18,2)), '|',
                        SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2))
                    )),
                2) AS aggregate_hash
            FROM dbo.fact_transactions ft
            WHERE ft.txn_month = @TxnMonth
            GROUP BY
                ft.date_key, ft.user_key, ft.card_key, ft.mcc_key, ft.currency,
                CAST(ft.txn_date AS DATE), CAST(ft.txn_month AS DATE)
        )
        INSERT INTO dbo.fact_transactions_daily (
            date_key, user_key, card_key, mcc_key, currency,
            txn_date, txn_month,
            txn_count_total, txn_count_success, txn_count_failed, txn_count_unknown,
            amount_sum_total, amount_sum_success, amount_sum_failed, amount_sum_unknown, amount_abs_sum_total,
            amount_avg_success, amount_min, amount_max,
            txn_count_chip_used, amount_sum_chip_used,
            gold_load_ts_max, aggregate_hash, run_id_last
        )
        SELECT
            s.date_key, s.user_key, s.card_key, s.mcc_key, s.currency,
            s.txn_date, s.txn_month,
            s.txn_count_total, s.txn_count_success, s.txn_count_failed, s.txn_count_unknown,
            s.amount_sum_total, s.amount_sum_success, s.amount_sum_failed, s.amount_sum_unknown, s.amount_abs_sum_total,
            s.amount_avg_success, s.amount_min, s.amount_max,
            s.txn_count_chip_used, s.amount_sum_chip_used,
            s.gold_load_ts_max, s.aggregate_hash, @RunId
        FROM src s
        LEFT JOIN dbo.fact_transactions_daily t
          ON t.date_key = s.date_key
         AND t.user_key = s.user_key
         AND t.card_key = s.card_key
         AND t.mcc_key  = s.mcc_key
         AND t.currency = s.currency
         AND t.txn_month = @TxnMonth
        WHERE t.date_key IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS',
            @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'FACT transactions daily aggregation upsert completed'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED',
            @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_job_fact_transactions_monthly_refresh_month
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource    BIGINT = 0;
    DECLARE @RowsInserted  BIGINT = 0;
    DECLARE @RowsUpdated   BIGINT = 0;
    DECLARE @RowsDeleted   BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL 
        SET @JobId = 'UNKNOWN';

    IF @TxnMonth IS NULL
        THROW 50001, 'TxnMonth is required (expected first day of month).', 1;

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId,
        @JobId,
        @StartTs,
        @ExecDate,
        @TxnMonth,
        'STARTED',
        'UPSERT fact_transactions_monthly monthly slice'
    );

    BEGIN TRY
        SELECT @RowsSource = COUNT_BIG(*)
        FROM (
            SELECT
                ft.txn_month, ft.user_key, ft.card_key, ft.mcc_key, ft.currency
            FROM dbo.fact_transactions ft
            WHERE ft.txn_month = @TxnMonth
            GROUP BY
                ft.txn_month, ft.user_key, ft.card_key, ft.mcc_key, ft.currency
        ) g;

        ;WITH src AS (
            SELECT
                CAST(ft.txn_month AS DATE) AS txn_month,
                ft.user_key,
                ft.card_key,
                ft.mcc_key,
                ft.currency,

                COUNT_BIG(1) AS txn_count_total,
                SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END) AS txn_count_success,
                SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END) AS txn_count_failed,
                SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END) AS txn_count_unknown,

                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)) AS amount_sum_total,
                CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_success,
                CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_failed,
                CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_unknown,
                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)) AS amount_abs_sum_total,

                CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)) AS amount_avg_success,
                CAST(MIN(ft.amount) AS DECIMAL(18,2)) AS amount_min,
                CAST(MAX(ft.amount) AS DECIMAL(18,2)) AS amount_max,

                SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END) AS txn_count_chip_used,
                CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_chip_used,

                MAX(ft.gold_load_ts) AS gold_load_ts_max,

                CONVERT(VARCHAR(64),
                    HASHBYTES('SHA2_256', CONCAT(
                        COUNT_BIG(1), '|',
                        SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)), '|',
                        CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(MIN(ft.amount) AS DECIMAL(18,2)), '|',
                        CAST(MAX(ft.amount) AS DECIMAL(18,2)), '|',
                        SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2))
                    )),
                2) AS aggregate_hash
            FROM dbo.fact_transactions ft
            WHERE ft.txn_month = @TxnMonth
            GROUP BY
                CAST(ft.txn_month AS DATE), ft.user_key, ft.card_key, ft.mcc_key, ft.currency
        )
        UPDATE t
           SET
               t.txn_count_total       = s.txn_count_total,
               t.txn_count_success     = s.txn_count_success,
               t.txn_count_failed      = s.txn_count_failed,
               t.txn_count_unknown     = s.txn_count_unknown,
               t.amount_sum_total      = s.amount_sum_total,
               t.amount_sum_success    = s.amount_sum_success,
               t.amount_sum_failed     = s.amount_sum_failed,
               t.amount_sum_unknown    = s.amount_sum_unknown,
               t.amount_abs_sum_total  = s.amount_abs_sum_total,
               t.amount_avg_success    = s.amount_avg_success,
               t.amount_min            = s.amount_min,
               t.amount_max            = s.amount_max,
               t.txn_count_chip_used   = s.txn_count_chip_used,
               t.amount_sum_chip_used  = s.amount_sum_chip_used,
               t.gold_load_ts_max      = s.gold_load_ts_max,
               t.aggregate_hash        = s.aggregate_hash,
               t.run_id_last           = @RunId
        FROM dbo.fact_transactions_monthly t
        JOIN src s
          ON s.txn_month = t.txn_month
         AND s.user_key  = t.user_key
         AND s.card_key  = t.card_key
         AND s.mcc_key   = t.mcc_key
         AND s.currency  = t.currency
        WHERE ISNULL(t.aggregate_hash,'') <> s.aggregate_hash;

        SET @RowsUpdated = @@ROWCOUNT;

        ;WITH src AS (
            SELECT
                CAST(ft.txn_month AS DATE) AS txn_month,
                ft.user_key,
                ft.card_key,
                ft.mcc_key,
                ft.currency,

                COUNT_BIG(1) AS txn_count_total,
                SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END) AS txn_count_success,
                SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END) AS txn_count_failed,
                SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END) AS txn_count_unknown,

                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)) AS amount_sum_total,
                CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_success,
                CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_failed,
                CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_unknown,
                CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)) AS amount_abs_sum_total,

                CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)) AS amount_avg_success,
                CAST(MIN(ft.amount) AS DECIMAL(18,2)) AS amount_min,
                CAST(MAX(ft.amount) AS DECIMAL(18,2)) AS amount_max,

                SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END) AS txn_count_chip_used,
                CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)) AS amount_sum_chip_used,

                MAX(ft.gold_load_ts) AS gold_load_ts_max,

                CONVERT(VARCHAR(64),
                    HASHBYTES('SHA2_256', CONCAT(
                        COUNT_BIG(1), '|',
                        SUM(CASE WHEN ft.is_success = 1 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success = 0 THEN 1 ELSE 0 END), '|',
                        SUM(CASE WHEN ft.is_success IS NULL THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success = 0 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.is_success IS NULL THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2)), '|',
                        CAST(SUM(CASE WHEN ft.amount IS NULL THEN 0 ELSE ABS(ft.amount) END) AS DECIMAL(18,2)), '|',
                        CAST(AVG(CASE WHEN ft.is_success = 1 THEN ft.amount END) AS DECIMAL(18,2)), '|',
                        CAST(MIN(ft.amount) AS DECIMAL(18,2)), '|',
                        CAST(MAX(ft.amount) AS DECIMAL(18,2)), '|',
                        SUM(CASE WHEN ft.is_chip_used = 1 THEN 1 ELSE 0 END), '|',
                        CAST(SUM(CASE WHEN ft.is_chip_used = 1 THEN ISNULL(ft.amount,0) ELSE 0 END) AS DECIMAL(18,2))
                    )),
                2) AS aggregate_hash
            FROM dbo.fact_transactions ft
            WHERE ft.txn_month = @TxnMonth
            GROUP BY
                CAST(ft.txn_month AS DATE), ft.user_key, ft.card_key, ft.mcc_key, ft.currency
        )
        INSERT INTO dbo.fact_transactions_monthly (
            txn_month, user_key, card_key, mcc_key, currency,
            txn_count_total, txn_count_success, txn_count_failed, txn_count_unknown,
            amount_sum_total, amount_sum_success, amount_sum_failed, amount_sum_unknown, amount_abs_sum_total,
            amount_avg_success, amount_min, amount_max,
            txn_count_chip_used, amount_sum_chip_used,
            gold_load_ts_max, aggregate_hash, run_id_last
        )
        SELECT
            s.txn_month, s.user_key, s.card_key, s.mcc_key, s.currency,
            s.txn_count_total, s.txn_count_success, s.txn_count_failed, s.txn_count_unknown,
            s.amount_sum_total, s.amount_sum_success, s.amount_sum_failed, s.amount_sum_unknown, s.amount_abs_sum_total,
            s.amount_avg_success, s.amount_min, s.amount_max,
            s.txn_count_chip_used, s.amount_sum_chip_used,
            s.gold_load_ts_max, s.aggregate_hash, @RunId
        FROM src s
        LEFT JOIN dbo.fact_transactions_monthly t
          ON t.txn_month = s.txn_month
         AND t.user_key  = s.user_key
         AND t.card_key  = s.card_key
         AND t.mcc_key   = s.mcc_key
         AND t.currency  = s.currency
        WHERE t.txn_month IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS',
            @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'FACT transactions monthly aggregation upsert completed'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED',
            @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_job_fact_transactions_refresh_month
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,  
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    DECLARE @RowsSource    BIGINT = 0;
    DECLARE @RowsInserted  BIGINT = 0;
    DECLARE @RowsUpdated   BIGINT = 0;
    DECLARE @RowsDeleted   BIGINT = 0;  -- optionnel

    -- Defaults
    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());

    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);
    
    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    IF @TxnMonth IS NULL
        THROW 50001, 'TxnMonth is required (expected first day of month).', 1;

    ------------------------------------------------------------------
    -- LOG START (append-only)
    ------------------------------------------------------------------
    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId,
        @JobId,
        @StartTs,
        @ExecDate,
        @TxnMonth,
        'STARTED',
        'UPSERT fact_transactions monthly slice'
    );

    BEGIN TRY
        ------------------------------------------------------------------
        -- rows_source
        ------------------------------------------------------------------
        SELECT @RowsSource = COUNT_BIG(*)
        FROM lh_wm_core.dbo.gold_fact_transactions
        WHERE txn_month = @TxnMonth;

        ------------------------------------------------------------------
        -- 1) UPDATE changed rows (hash diff)  [CTE used ONCE here]
        ------------------------------------------------------------------
        ;WITH src AS (
            SELECT
                CAST(f.transaction_id AS VARCHAR(64)) AS transaction_id,

                d.date_key,
                u.user_key,
                c.card_key,
                m.mcc_key,

                CAST(f.txn_date  AS DATE) AS txn_date,
                CAST(f.txn_month AS DATE) AS txn_month,

                CAST(f.amount AS DECIMAL(18,2)) AS amount,
                CAST('USD' AS VARCHAR(10))       AS currency,

                CAST(f.is_success AS BIT)           AS is_success,
                CAST(f.error_code  AS VARCHAR(50))  AS error_code,
                CAST(f.is_chip_used AS BIT)         AS is_chip_used,

                CAST(NULL AS VARCHAR(200))              AS merchant_name,
                CAST(f.merchant_city  AS VARCHAR(100))  AS merchant_city,
                CAST(f.merchant_state AS VARCHAR(50))   AS merchant_state,
                CAST(f.zip            AS VARCHAR(20))   AS merchant_zip,

                CAST(f.gold_load_ts AS DATETIME2(3)) AS gold_load_ts,

                -- reuse hash from Silver/Gold (business-only)
                CAST(f.record_hash AS VARCHAR(64)) AS record_hash
            FROM lh_wm_core.dbo.gold_fact_transactions f
            JOIN dbo.dim_date d
              ON d.date_id = CONVERT(INT, CONVERT(CHAR(8), CAST(f.txn_date AS DATE), 112))
            JOIN dbo.dim_user u
              ON u.client_id = CAST(f.client_id AS VARCHAR(64))
            JOIN dbo.dim_card c
              ON c.card_id = CAST(f.card_id AS VARCHAR(64))
            JOIN dbo.dim_mcc m
              ON m.mcc_code = CAST(f.mcc_code AS INT)
            WHERE f.txn_month = @TxnMonth
        )
        UPDATE t
           SET
               t.date_key       = s.date_key,
               t.user_key       = s.user_key,
               t.card_key       = s.card_key,
               t.mcc_key        = s.mcc_key,
               t.txn_date       = s.txn_date,
               t.txn_month      = s.txn_month,
               t.amount         = s.amount,
               t.currency       = s.currency,
               t.is_success     = s.is_success,
               t.error_code     = s.error_code,
               t.is_chip_used   = s.is_chip_used,
               t.merchant_name  = s.merchant_name,
               t.merchant_city  = s.merchant_city,
               t.merchant_state = s.merchant_state,
               t.merchant_zip   = s.merchant_zip,
               t.record_hash    = s.record_hash,
               t.gold_load_ts   = s.gold_load_ts
        FROM dbo.fact_transactions t
        JOIN src s
          ON s.transaction_id = t.transaction_id
         AND t.txn_month = @TxnMonth
        WHERE ISNULL(t.record_hash,'') <> s.record_hash;

        SET @RowsUpdated = @@ROWCOUNT;

        ------------------------------------------------------------------
        -- 2) INSERT new rows  [CTE duplicated and used ONCE here]
        ------------------------------------------------------------------
        ;WITH src AS (
            SELECT
                CAST(f.transaction_id AS VARCHAR(64)) AS transaction_id,

                d.date_key,
                u.user_key,
                c.card_key,
                m.mcc_key,

                CAST(f.txn_date  AS DATE) AS txn_date,
                CAST(f.txn_month AS DATE) AS txn_month,

                CAST(f.amount AS DECIMAL(18,2)) AS amount,
                CAST('USD' AS VARCHAR(10))       AS currency,

                CAST(f.is_success AS BIT)           AS is_success,
                CAST(f.error_code  AS VARCHAR(50))  AS error_code,
                CAST(f.is_chip_used AS BIT)         AS is_chip_used,

                CAST(NULL AS VARCHAR(200))              AS merchant_name,
                CAST(f.merchant_city  AS VARCHAR(100))  AS merchant_city,
                CAST(f.merchant_state AS VARCHAR(50))   AS merchant_state,
                CAST(f.zip            AS VARCHAR(20))   AS merchant_zip,

                CAST(f.gold_load_ts AS DATETIME2(3)) AS gold_load_ts,

                CAST(f.record_hash AS VARCHAR(64)) AS record_hash
            FROM lh_wm_core.dbo.gold_fact_transactions f
            JOIN dbo.dim_date d
              ON d.date_id = CONVERT(INT, CONVERT(CHAR(8), CAST(f.txn_date AS DATE), 112))
            JOIN dbo.dim_user u
              ON u.client_id = CAST(f.client_id AS VARCHAR(64))
            JOIN dbo.dim_card c
              ON c.card_id = CAST(f.card_id AS VARCHAR(64))
            JOIN dbo.dim_mcc m
              ON m.mcc_code = CAST(f.mcc_code AS INT)
            WHERE f.txn_month = @TxnMonth
        )
        INSERT INTO dbo.fact_transactions (
            transaction_id,
            date_key, user_key, card_key, mcc_key,
            txn_date, txn_month,
            amount, currency,
            is_success, error_code, is_chip_used,
            merchant_name, merchant_city, merchant_state, merchant_zip,
            record_hash,
            gold_load_ts
        )
        SELECT
            s.transaction_id,
            s.date_key, s.user_key, s.card_key, s.mcc_key,
            s.txn_date, s.txn_month,
            s.amount, s.currency,
            s.is_success, s.error_code, s.is_chip_used,
            s.merchant_name, s.merchant_city, s.merchant_state, s.merchant_zip,
            s.record_hash,
            s.gold_load_ts
        FROM src s
        LEFT JOIN dbo.fact_transactions t
          ON t.transaction_id = s.transaction_id
         AND t.txn_month = @TxnMonth
        WHERE t.transaction_id IS NULL;

        SET @RowsInserted = @@ROWCOUNT;

        ------------------------------------------------------------------
        -- 3) (OPTIONNEL) DELETE missing rows for strict replication
        --    If you want it, same rule: define src again and use it once.
        ------------------------------------------------------------------
        /*
        ;WITH src AS (
            SELECT CAST(transaction_id AS VARCHAR(64)) AS transaction_id
            FROM lh_wm_core.dbo.gold_fact_transactions
            WHERE txn_month = @TxnMonth
        )
        DELETE t
        FROM dbo.fact_transactions t
        LEFT JOIN src s
          ON s.transaction_id = t.transaction_id
        WHERE t.txn_month = @TxnMonth
          AND s.transaction_id IS NULL;

        SET @RowsDeleted = @@ROWCOUNT;
        */

        ------------------------------------------------------------------
        -- LOG SUCCESS
        ------------------------------------------------------------------
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS',
            @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            'FACT transactions monthly upsert completed'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, txn_month,
            status, rows_source, rows_inserted, rows_updated, rows_deleted, message
        )
        VALUES (
            @RunId,
            @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED',
            @RowsSource, @RowsInserted, @RowsUpdated, @RowsDeleted,
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_pub_check_aggregates_freshness
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);
    DECLARE @MaxTs DATETIME2(3);

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());
    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';
    
    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId,
        @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'PUBLISH check: aggregates freshness'
    );

    BEGIN TRY
        SELECT @MaxTs = MAX(gold_load_ts_max)
        FROM dbo.fact_transactions_monthly
        WHERE txn_month = @TxnMonth;

        IF @MaxTs IS NULL OR @MaxTs < DATEADD(HOUR, -24, SYSUTCDATETIME())
            THROW 51002, 'Aggregates are stale (older than 24h).', 1;

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'pub_agg_freshness',
            SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            'PASS', 0,
            CONCAT('Max gold_load_ts_max = ', CONVERT(VARCHAR(30), @MaxTs, 126))
        );

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end,
            exec_date, txn_month, status, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', 'Aggregates freshness OK'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();
        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end,
            exec_date, txn_month, status, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', LEFT(ERROR_MESSAGE(), 2000)
        );
        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_pub_check_aggregates_monthly_present
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @TxnMonth DATE,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);
    DECLARE @RowCount BIGINT = 0;

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());
    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);
    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, txn_month, status, message
    )
    VALUES (
        @RunId, @JobId,
        @StartTs, @ExecDate, @TxnMonth,
        'STARTED', 'PUBLISH check: aggregates monthly present'
    );

    BEGIN TRY
        SELECT @RowCount = COUNT_BIG(*)
        FROM dbo.fact_transactions_monthly
        WHERE txn_month = @TxnMonth;

        INSERT INTO dbo.wh_dq_check_result (
            run_id, check_code, exec_ts, exec_date, txn_month, status, issue_count, message
        )
        VALUES (
            @RunId, 'pub_agg_monthly_present',
            SYSUTCDATETIME(), @ExecDate, @TxnMonth,
            CASE WHEN @RowCount > 0 THEN 'PASS' ELSE 'FAIL' END,
            CASE WHEN @RowCount > 0 THEN 0 ELSE 1 END,
            CONCAT('Rows in fact_transactions_monthly = ', @RowCount)
        );

        IF @RowCount = 0
            THROW 51001, 'No monthly aggregates found for TxnMonth.', 1;

        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end,
            exec_date, txn_month, status, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'SUCCESS', 'Aggregates monthly present'
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();
        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end,
            exec_date, txn_month, status, message
        )
        VALUES (
            @RunId, @JobId,
            @StartTs, @EndTs, @ExecDate, @TxnMonth,
            'FAILED', LEFT(ERROR_MESSAGE(), 2000)
        );
        THROW;
    END CATCH
END;


CREATE OR ALTER   PROCEDURE dbo.sp_pub_refresh_semantic_model
    @RunId    VARCHAR(64) = NULL,
    @JobId    VARCHAR(64) = NULL,
    @ExecDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    IF @RunId IS NULL OR LTRIM(RTRIM(@RunId)) = ''
        SET @RunId = CONVERT(VARCHAR(64), NEWID());
    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);
    IF @JobId IS NULL
        SET @JobId = 'UNKNOWN';

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, status, message
    )
    VALUES (
        @RunId, @JobId,
        @StartTs, @ExecDate,
        'STARTED', 'Trigger semantic model refresh'
    );

    -- L’action réelle est faite par le pipeline (activity Refresh)
    SET @EndTs = SYSUTCDATETIME();

    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_ts_end,
        exec_date, status, message
    )
    VALUES (
        @RunId, @JobId,
        @StartTs, @EndTs,
        @ExecDate, 'SUCCESS',
        'Semantic model refresh triggered'
    );
END;



CREATE OR ALTER   PROCEDURE dbo.sp_pub_wh_run_refresh
    @RunId    VARCHAR(64),
    @ExecDate DATE        = NULL,
    @JobId    VARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTs DATETIME2(3) = SYSUTCDATETIME();
    DECLARE @EndTs   DATETIME2(3);

    -- Defaults
    IF @ExecDate IS NULL
        SET @ExecDate = CAST(GETDATE() AS DATE);

    IF @JobId IS NULL OR LTRIM(RTRIM(@JobId)) = ''
        SET @JobId = 'wh_run_upsert';

    -- Run-level fields
    DECLARE @run_exec_date     DATE = NULL;
    DECLARE @run_txn_month     DATE = NULL;
    DECLARE @run_ts_start      DATETIME2(3) = NULL;
    DECLARE @run_ts_end        DATETIME2(3) = NULL;
    DECLARE @duration_sec      BIGINT = NULL;

    DECLARE @jobs_total        INT = 0;
    DECLARE @jobs_failed       INT = 0;
    DECLARE @jobs_success      INT = 0;
    DECLARE @jobs_started      INT = 0;
    DECLARE @critical_failed   INT = 0;

    DECLARE @rows_source       BIGINT = 0;
    DECLARE @rows_inserted     BIGINT = 0;
    DECLARE @rows_updated      BIGINT = 0;
    DECLARE @rows_deleted      BIGINT = 0;

    DECLARE @dq_status         VARCHAR(16) = NULL;
    DECLARE @dq_fail_count     INT = 0;
    DECLARE @dq_issue_count    BIGINT = 0;

    DECLARE @last_message      VARCHAR(2000) = NULL;
    DECLARE @run_status        VARCHAR(16) = 'RUNNING';

    ----------------------------------------------------------------------
    -- LOG START (append-only)
    ----------------------------------------------------------------------
    INSERT INTO dbo.wh_job_run_log (
        run_id, job_id, exec_ts_start, exec_date, status, message
    )
    VALUES (
        @RunId, @JobId, @StartTs, @ExecDate, 'STARTED',
        'Upsert run-level metrics into dbo.wh_run'
    );

    BEGIN TRY
        ----------------------------------------------------------------------
        -- 1) Latest status per job_id for this run (exclude @JobId from metrics)
        --    wh_job_run_log is append-only => pick last row per job_id.
        ----------------------------------------------------------------------
        ;WITH job_events AS (
            SELECT
                l.run_id,
                l.job_id,
                l.exec_date,
                l.txn_month,
                l.exec_ts_start,
                l.exec_ts_end,
                l.status,
                l.rows_source,
                l.rows_inserted,
                l.rows_updated,
                l.rows_deleted,
                l.message,
                ROW_NUMBER() OVER (
                    PARTITION BY l.run_id, l.job_id
                    ORDER BY COALESCE(l.exec_ts_end, l.exec_ts_start) DESC,
                             l.exec_ts_start DESC
                ) AS rn
            FROM dbo.wh_job_run_log l
            WHERE l.run_id = @RunId
              AND l.job_id <> @JobId
        ),
        jobs_latest AS (
            SELECT
                run_id,
                job_id,
                exec_date,
                txn_month,
                exec_ts_start,
                exec_ts_end,
                status,
                rows_source,
                rows_inserted,
                rows_updated,
                rows_deleted,
                message
            FROM job_events
            WHERE rn = 1
        )
        SELECT
            @run_exec_date = COALESCE(MAX(j.exec_date), @ExecDate),
            @run_txn_month = MAX(j.txn_month),
            @run_ts_start  = MIN(j.exec_ts_start),
            @run_ts_end    = MAX(j.exec_ts_end),

            @jobs_total    = COUNT(1),
            @jobs_failed   = SUM(CASE WHEN j.status = 'FAILED'  THEN 1 ELSE 0 END),
            @jobs_success  = SUM(CASE WHEN j.status = 'SUCCESS' THEN 1 ELSE 0 END),

            -- started/running OR no end timestamp => still in progress
            @jobs_started  = SUM(CASE WHEN j.status IN ('STARTED','RUNNING') OR j.exec_ts_end IS NULL THEN 1 ELSE 0 END),

            @rows_source   = COALESCE(SUM(COALESCE(j.rows_source,   0)), 0),
            @rows_inserted = COALESCE(SUM(COALESCE(j.rows_inserted, 0)), 0),
            @rows_updated  = COALESCE(SUM(COALESCE(j.rows_updated,  0)), 0),
            @rows_deleted  = COALESCE(SUM(COALESCE(j.rows_deleted,  0)), 0)
        FROM jobs_latest j;

        IF @run_ts_start IS NOT NULL
            SET @duration_sec = DATEDIFF(SECOND, @run_ts_start, COALESCE(@run_ts_end, SYSUTCDATETIME()));

        ----------------------------------------------------------------------
        -- 2) critical_failed using wh_ctl_job mapping (job_code = job_id)
        ----------------------------------------------------------------------
        ;WITH job_events AS (
            SELECT
                l.run_id,
                l.job_id,
                l.status,
                ROW_NUMBER() OVER (
                    PARTITION BY l.run_id, l.job_id
                    ORDER BY COALESCE(l.exec_ts_end, l.exec_ts_start) DESC,
                             l.exec_ts_start DESC
                ) AS rn
            FROM dbo.wh_job_run_log l
            WHERE l.run_id = @RunId
              AND l.job_id <> @JobId
        ),
        jobs_latest AS (
            SELECT run_id, job_id, status
            FROM job_events
            WHERE rn = 1
        )
        SELECT
            @critical_failed = COALESCE(SUM(CASE WHEN jl.status = 'FAILED' AND COALESCE(c.is_critical, 0) = 1 THEN 1 ELSE 0 END), 0)
        FROM jobs_latest jl
        LEFT JOIN dbo.wh_ctl_job c
            ON c.job_code = jl.job_id;

        ----------------------------------------------------------------------
        -- 3) DQ rollup (latest per check_code)
        ----------------------------------------------------------------------
        ;WITH dq_events AS (
            SELECT
                d.run_id,
                d.check_code,
                d.exec_ts,
                d.status,
                d.issue_count,
                d.message,
                ROW_NUMBER() OVER (
                    PARTITION BY d.run_id, d.check_code
                    ORDER BY d.exec_ts DESC
                ) AS rn
            FROM dbo.wh_dq_check_result d
            WHERE d.run_id = @RunId
        ),
        dq_latest AS (
            SELECT run_id, check_code, status, issue_count, message
            FROM dq_events
            WHERE rn = 1
        )
        SELECT
            @dq_fail_count  = COALESCE(SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END), 0),
            @dq_issue_count = COALESCE(SUM(COALESCE(issue_count, 0)), 0),
            @dq_status =
                CASE
                    WHEN COALESCE(SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END), 0) > 0 THEN 'FAIL'
                    WHEN COALESCE(SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END), 0) > 0 THEN 'PASS'
                    WHEN COALESCE(SUM(CASE WHEN status = 'INFO' THEN 1 ELSE 0 END), 0) > 0 THEN 'INFO'
                    ELSE NULL
                END
        FROM dq_latest;

        ----------------------------------------------------------------------
        -- 4) last_message (priority: failed job msg > dq fail msg > last job msg)
        ----------------------------------------------------------------------
        DECLARE @msg_failed_job VARCHAR(2000) = NULL;
        DECLARE @msg_dq_fail    VARCHAR(2000) = NULL;
        DECLARE @msg_last_job   VARCHAR(2000) = NULL;

        SELECT TOP (1)
            @msg_failed_job = LEFT(l.message, 2000)
        FROM dbo.wh_job_run_log l
        WHERE l.run_id = @RunId
          AND l.job_id <> @JobId
          AND l.status = 'FAILED'
          AND l.message IS NOT NULL AND LTRIM(RTRIM(l.message)) <> ''
        ORDER BY COALESCE(l.exec_ts_end, l.exec_ts_start) DESC;

        SELECT TOP (1)
            @msg_dq_fail = LEFT(d.message, 2000)
        FROM dbo.wh_dq_check_result d
        WHERE d.run_id = @RunId
          AND d.status = 'FAIL'
          AND d.message IS NOT NULL AND LTRIM(RTRIM(d.message)) <> ''
        ORDER BY d.exec_ts DESC;

        SELECT TOP (1)
            @msg_last_job = LEFT(l.message, 2000)
        FROM dbo.wh_job_run_log l
        WHERE l.run_id = @RunId
          AND l.job_id <> @JobId
          AND l.message IS NOT NULL AND LTRIM(RTRIM(l.message)) <> ''
        ORDER BY COALESCE(l.exec_ts_end, l.exec_ts_start) DESC;

        SET @last_message = COALESCE(@msg_failed_job, @msg_dq_fail, @msg_last_job);

        ----------------------------------------------------------------------
        -- 5) run_status (EXCLUDING @JobId)
        --    Priority: RUNNING > FAILED > SUCCESS
        --    FAILED if any failed (or critical failed) OR DQ FAIL
        ----------------------------------------------------------------------
        IF @jobs_started > 0
            SET @run_status = 'RUNNING';
        ELSE IF @jobs_failed > 0 OR @critical_failed > 0 OR @dq_status = 'FAIL'
            SET @run_status = 'FAILED';
        ELSE
            SET @run_status = 'SUCCESS';

        ----------------------------------------------------------------------
        -- 6) UPSERT dbo.wh_run (one row per run_id)
        ----------------------------------------------------------------------
        MERGE dbo.wh_run AS tgt
        USING (SELECT @RunId AS run_id) AS src
            ON tgt.run_id = src.run_id
        WHEN MATCHED THEN
            UPDATE SET
                exec_date       = @run_exec_date,
                exec_ts_start   = @run_ts_start,
                exec_ts_end     = @run_ts_end,
                txn_month       = @run_txn_month,
                run_status      = @run_status,
                duration_sec    = @duration_sec,
                jobs_total      = @jobs_total,
                jobs_failed     = @jobs_failed,
                jobs_success    = @jobs_success,
                jobs_started    = @jobs_started,
                critical_failed = @critical_failed,
                rows_source     = @rows_source,
                rows_inserted   = @rows_inserted,
                rows_updated    = @rows_updated,
                rows_deleted    = @rows_deleted,
                dq_status       = @dq_status,
                dq_fail_count   = @dq_fail_count,
                dq_issue_count  = @dq_issue_count,
                last_message    = @last_message
        WHEN NOT MATCHED THEN
            INSERT (
                run_id, exec_date, exec_ts_start, exec_ts_end, txn_month,
                run_status, duration_sec,
                jobs_total, jobs_failed, jobs_success, jobs_started, critical_failed,
                rows_source, rows_inserted, rows_updated, rows_deleted,
                dq_status, dq_fail_count, dq_issue_count, last_message
            )
            VALUES (
                @RunId, @run_exec_date, @run_ts_start, @run_ts_end, @run_txn_month,
                @run_status, @duration_sec,
                @jobs_total, @jobs_failed, @jobs_success, @jobs_started, @critical_failed,
                @rows_source, @rows_inserted, @rows_updated, @rows_deleted,
                @dq_status, @dq_fail_count, @dq_issue_count, @last_message
            );

        ----------------------------------------------------------------------
        -- LOG SUCCESS (append-only)
        ----------------------------------------------------------------------
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, status, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate, 'SUCCESS',
            CONCAT(
                'wh_run upsert OK. run_status=', @run_status,
                ', jobs_total=', COALESCE(CONVERT(VARCHAR(20), @jobs_total), '0'),
                ', jobs_failed=', COALESCE(CONVERT(VARCHAR(20), @jobs_failed), '0'),
                ', critical_failed=', COALESCE(CONVERT(VARCHAR(20), @critical_failed), '0'),
                ', dq_status=', COALESCE(@dq_status, 'NULL')
            )
        );
    END TRY
    BEGIN CATCH
        SET @EndTs = SYSUTCDATETIME();

        INSERT INTO dbo.wh_job_run_log (
            run_id, job_id, exec_ts_start, exec_ts_end, exec_date, status, message
        )
        VALUES (
            @RunId, @JobId, @StartTs, @EndTs, @ExecDate, 'FAILED',
            LEFT(ERROR_MESSAGE(), 2000)
        );

        THROW;
    END CATCH
END;





