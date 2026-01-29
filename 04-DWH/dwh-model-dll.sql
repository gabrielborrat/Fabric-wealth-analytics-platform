CREATE TABLE [wh_wm_analytics].[dbo].[ctrl_conformance]
(
	[check_ts] [datetime2](3) NOT NULL,
	[txn_month] [date] NOT NULL,
	[metric_name] [varchar](128) NOT NULL,
	[metric_value] [bigint] NOT NULL,
	[status] [varchar](16) NOT NULL,
	[details] [varchar](2000) NULL
)
GO
CREATE TABLE [wh_wm_analytics].[dbo].[ctrl_duplicates]
(
	[check_ts] [datetime2](3) NOT NULL,
	[txn_month] [date] NOT NULL,
	[metric_name] [varchar](128) NOT NULL,
	[metric_value] [bigint] NOT NULL,
	[status] [varchar](16) NOT NULL,
	[details] [varchar](2000) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[ctrl_publish_status]
(
	[publish_ts] [datetime2](3) NOT NULL,
	[txn_month] [date] NOT NULL,
	[status] [varchar](16) NOT NULL,
	[reason] [varchar](2000) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[ctrl_reconciliation]
(
	[check_ts] [datetime2](3) NOT NULL,
	[txn_month] [date] NOT NULL,
	[metric_name] [varchar](128) NOT NULL,
	[gold_value] [decimal](38,6) NULL,
	[wh_value] [decimal](38,6) NULL,
	[delta_value] [decimal](38,6) NULL,
	[tolerance_abs] [decimal](38,6) NULL,
	[status] [varchar](16) NOT NULL,
	[details] [varchar](2000) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[dim_card]
(
	[card_key] [bigint] IDENTITY NOT NULL,
	[card_id] [varchar](64) NOT NULL,
	[client_id] [varchar](64) NOT NULL,
	[card_brand] [varchar](50) NULL,
	[card_type] [varchar](50) NULL,
	[has_chip] [bit] NULL,
	[credit_limit] [decimal](18,2) NULL,
	[num_cards_issued] [int] NULL,
	[card_on_dark_web] [bit] NULL,
	[record_hash] [varchar](64) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[dim_date]
(
	[date_key] [bigint] IDENTITY NOT NULL,
	[date_id] [int] NOT NULL,
	[full_date] [date] NOT NULL,
	[year] [int] NULL,
	[quarter] [int] NULL,
	[month] [int] NULL,
	[week] [int] NULL,
	[day_of_week] [int] NULL,
	[is_weekend] [bit] NULL,
	[is_business_day] [bit] NULL,
	[record_hash] [varchar](64) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[dim_mcc]
(
	[mcc_key] [bigint] IDENTITY NOT NULL,
	[mcc_code] [int] NOT NULL,
	[mcc_description] [varchar](200) NULL,
	[mcc_category] [varchar](100) NULL,
	[record_hash] [varchar](64) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[dim_month]
(
	[month_start] [date] NOT NULL,
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[yyyymm] [int] NOT NULL,
	[month_label] [varchar](7) NOT NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[dim_user]
(
	[user_key] [bigint] IDENTITY NOT NULL,
	[client_id] [varchar](64) NOT NULL,
	[current_age] [int] NULL,
	[yearly_income] [decimal](18,2) NULL,
	[total_debt] [decimal](18,2) NULL,
	[credit_score] [int] NULL,
	[address] [varchar](500) NULL,
	[record_hash] [varchar](64) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[fact_transactions]
(
	[transaction_id] [varchar](64) NOT NULL,
	[date_key] [bigint] NOT NULL,
	[user_key] [bigint] NOT NULL,
	[card_key] [bigint] NOT NULL,
	[mcc_key] [bigint] NOT NULL,
	[txn_date] [date] NOT NULL,
	[txn_month] [date] NOT NULL,
	[amount] [decimal](18,2) NULL,
	[currency] [varchar](10) NULL,
	[is_success] [bit] NULL,
	[error_code] [varchar](50) NULL,
	[is_chip_used] [bit] NULL,
	[merchant_name] [varchar](200) NULL,
	[merchant_city] [varchar](100) NULL,
	[merchant_state] [varchar](50) NULL,
	[merchant_zip] [varchar](20) NULL,
	[record_hash] [varchar](64) NOT NULL,
	[gold_load_ts] [datetime2](3) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[fact_transactions_daily]
(
	[date_key] [bigint] NOT NULL,
	[user_key] [bigint] NOT NULL,
	[card_key] [bigint] NOT NULL,
	[mcc_key] [bigint] NOT NULL,
	[currency] [varchar](10) NOT NULL,
	[txn_date] [date] NOT NULL,
	[txn_month] [date] NOT NULL,
	[txn_count_total] [bigint] NOT NULL,
	[txn_count_success] [bigint] NOT NULL,
	[txn_count_failed] [bigint] NOT NULL,
	[txn_count_unknown] [bigint] NOT NULL,
	[amount_sum_total] [decimal](18,2) NOT NULL,
	[amount_sum_success] [decimal](18,2) NOT NULL,
	[amount_sum_failed] [decimal](18,2) NOT NULL,
	[amount_sum_unknown] [decimal](18,2) NOT NULL,
	[amount_abs_sum_total] [decimal](18,2) NOT NULL,
	[amount_avg_success] [decimal](18,2) NULL,
	[amount_min] [decimal](18,2) NULL,
	[amount_max] [decimal](18,2) NULL,
	[txn_count_chip_used] [bigint] NOT NULL,
	[amount_sum_chip_used] [decimal](18,2) NOT NULL,
	[gold_load_ts_max] [datetime2](3) NULL,
	[aggregate_hash] [varchar](64) NOT NULL,
	[run_id_last] [varchar](64) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[fact_transactions_monthly]
(
	[txn_month] [date] NOT NULL,
	[user_key] [bigint] NOT NULL,
	[card_key] [bigint] NOT NULL,
	[mcc_key] [bigint] NOT NULL,
	[currency] [varchar](10) NOT NULL,
	[txn_count_total] [bigint] NOT NULL,
	[txn_count_success] [bigint] NOT NULL,
	[txn_count_failed] [bigint] NOT NULL,
	[txn_count_unknown] [bigint] NOT NULL,
	[amount_sum_total] [decimal](18,2) NOT NULL,
	[amount_sum_success] [decimal](18,2) NOT NULL,
	[amount_sum_failed] [decimal](18,2) NOT NULL,
	[amount_sum_unknown] [decimal](18,2) NOT NULL,
	[amount_abs_sum_total] [decimal](18,2) NOT NULL,
	[amount_avg_success] [decimal](18,2) NULL,
	[amount_min] [decimal](18,2) NULL,
	[amount_max] [decimal](18,2) NULL,
	[txn_count_chip_used] [bigint] NOT NULL,
	[amount_sum_chip_used] [decimal](18,2) NOT NULL,
	[gold_load_ts_max] [datetime2](3) NULL,
	[aggregate_hash] [varchar](64) NOT NULL,
	[run_id_last] [varchar](64) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[wh_ctl_job]
(
	[job_group] [varchar](50) NOT NULL,
	[job_order] [int] NOT NULL,
	[job_code] [varchar](100) NOT NULL,
	[sp_schema] [varchar](50) NOT NULL,
	[sp_name] [varchar](128) NOT NULL,
	[enabled] [bit] NOT NULL,
	[is_critical] [bit] NOT NULL,
	[needs_txn_month] [bit] NOT NULL,
	[needs_exec_date] [bit] NOT NULL,
	[notes] [varchar](500) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[wh_dq_check_result]
(
	[run_id] [varchar](64) NOT NULL,
	[check_code] [varchar](100) NOT NULL,
	[exec_ts] [datetime2](3) NOT NULL,
	[exec_date] [date] NULL,
	[txn_month] [date] NULL,
	[status] [varchar](16) NOT NULL,
	[issue_count] [bigint] NULL,
	[message] [varchar](2000) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[wh_job_run_log]
(
	[run_id] [varchar](64) NOT NULL,
	[job_id] [varchar](128) NOT NULL,
	[exec_ts_start] [datetime2](3) NOT NULL,
	[exec_ts_end] [datetime2](3) NULL,
	[exec_date] [date] NULL,
	[txn_month] [date] NULL,
	[status] [varchar](16) NOT NULL,
	[rows_inserted] [bigint] NULL,
	[rows_updated] [bigint] NULL,
	[rows_deleted] [bigint] NULL,
	[rows_source] [bigint] NULL,
	[message] [varchar](2000) NULL
)
GO

CREATE TABLE [wh_wm_analytics].[dbo].[wh_run]
(
	[run_id] [varchar](64) NOT NULL,
	[exec_date] [date] NULL,
	[exec_ts_start] [datetime2](3) NULL,
	[exec_ts_end] [datetime2](3) NULL,
	[txn_month] [date] NULL,
	[run_status] [varchar](16) NOT NULL,
	[duration_sec] [bigint] NULL,
	[jobs_total] [int] NULL,
	[jobs_failed] [int] NULL,
	[jobs_success] [int] NULL,
	[jobs_started] [int] NULL,
	[critical_failed] [int] NULL,
	[rows_source] [bigint] NULL,
	[rows_inserted] [bigint] NULL,
	[rows_updated] [bigint] NULL,
	[rows_deleted] [bigint] NULL,
	[dq_status] [varchar](16) NULL,
	[dq_fail_count] [int] NULL,
	[dq_issue_count] [bigint] NULL,
	[last_message] [varchar](2000) NULL
)
GO