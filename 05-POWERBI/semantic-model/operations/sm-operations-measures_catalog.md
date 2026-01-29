# SM OPS – Observability Measures Documentation

> **Scope**: This document describes all DAX measures implemented in the **SM OPS – Observability** semantic model.
> It is designed for **portfolio presentation, client demos, governance reviews, and maintenance**.

---

## OPS / DQ — Data Quality

### OPS DQ Fail Count
```DAX
OPS DQ Fail Count =
CALCULATE (
    COUNTROWS ( wh_dq_check_result ),
    wh_dq_check_result[check_status] = "FAILED"
)
```

### OPS DQ Overall Status
```DAX
OPS DQ Overall Status =
IF ( [OPS DQ Fail Count] > 0, "FAILED", "PASSED" )
```

### OPS DQ Status Color
```DAX
OPS DQ Status Color =
SWITCH (
    [OPS DQ Overall Status],
    "FAILED", "#D13438",
    "PASSED", "#107C10"
)
```

---

## OPS / Freshness

### OPS Daily Last Date Present
```DAX
OPS Daily Last Date Present =
MAX ( fact_transactions_daily[date_key] )
```

### OPS Daily Freshness (days)
```DAX
OPS Daily Freshness (days) =
DATEDIFF ( [OPS Daily Last Date Present], TODAY (), DAY )
```

### OPS Monthly Last Month Present
```DAX
OPS Monthly Last Month Present =
MAX ( fact_transactions_monthly[month_key] )
```

### OPS Monthly Last Month Present (Label)
```DAX
OPS Monthly Last Month Present (Label) =
FORMAT ( [OPS Monthly Last Month Present], "YYYY-MM" )
```

### OPS Monthly Freshness (days)
```DAX
OPS Monthly Freshness (days) =
DATEDIFF ( [OPS Monthly Last Month Present], TODAY (), DAY )
```

### OPS Monthly Current Month Present
```DAX
OPS Monthly Current Month Present =
VAR CurrentMonthKey = VALUE ( FORMAT ( TODAY (), "YYYYMM" ) )
RETURN
IF ( [OPS Monthly Last Month Present] = CurrentMonthKey, 1, 0 )
```

### OPS Monthly Current Month Label
```DAX
OPS Monthly Current Month Label =
FORMAT ( TODAY (), "YYYY-MM" )
```

### OPS Monthly Aggregate Color
```DAX
OPS Monthly Aggregate Color =
IF ( [OPS Monthly Freshness (days)] <= 31, "#107C10", "#D13438" )
```

---

## OPS / Health

### OPS Critical Gate Status
```DAX
OPS Critical Gate Status =
IF (
    [OPS DQ Fail Count] > 0
        || [OPS Jobs Failed] > 0,
    "CRITICAL",
    "OK"
)
```

### OPS Health Severity Code
```DAX
OPS Health Severity Code =
SWITCH (
    [OPS Critical Gate Status],
    "CRITICAL", 3,
    "OK", 1
)
```

### OPS Health Severity Color
```DAX
OPS Health Severity Color =
SWITCH (
    [OPS Health Severity Code],
    3, "#D13438",
    1, "#107C10"
)
```

---

## OPS / Jobs

### OPS Jobs Executed
```DAX
OPS Jobs Executed =
COUNTROWS ( wh_job_run_log )
```

### OPS Jobs Failed
```DAX
OPS Jobs Failed =
CALCULATE (
    COUNTROWS ( wh_job_run_log ),
    wh_job_run_log[run_status] = "FAILED"
)
```

### OPS Jobs Executed Color
```DAX
OPS Jobs Executed Color =
"#0078D4"
```

### OPS Jobs Failed Color
```DAX
OPS Jobs Failed Color =
IF ( [OPS Jobs Failed] > 0, "#D13438", "#107C10" )
```

---

## OPS / Run

### OPS Latest RunId
```DAX
OPS Latest RunId =
MAX ( wh_run[run_id] )
```

### OPS Selected RunId
```DAX
OPS Selected RunId =
SELECTEDVALUE ( wh_run[run_id] )
```

### OPS Selected RunId (Latest in filter)
```DAX
OPS Selected RunId (Latest in filter) =
COALESCE ( [OPS Selected RunId], [OPS Latest RunId] )
```

### OPS Run Status
```DAX
OPS Run Status =
SELECTEDVALUE ( wh_run[run_status] )
```

### OPS Run Status Color
```DAX
OPS Run Status Color =
SWITCH (
    [OPS Run Status],
    "FAILED", "#D13438",
    "SUCCESS", "#107C10",
    "RUNNING", "#FFB900",
    "#605E5C"
)
```

### OPS Duration (min)
```DAX
OPS Duration (min) =
DIVIDE ( SUM ( wh_run[duration_sec] ), 60 )
```

### OPS Duration (min) Color
```DAX
OPS Duration (min) Color =
IF ( [OPS Duration (min)] > 60, "#D13438", "#107C10" )
```

### OPS Last Successful RunId
```DAX
OPS Last Successful RunId =
CALCULATE (
    MAX ( wh_run[run_id] ),
    FILTER ( ALL ( wh_run ), wh_run[run_status] = "SUCCESS" )
)
```

### OPS Last Successful Run End Ts
```DAX
OPS Last Successful Run End Ts =
CALCULATE (
    MAX ( wh_run[end_ts] ),
    FILTER ( ALL ( wh_run ), wh_run[run_status] = "SUCCESS" )
)
```

---

## OPS / RunHistory

> **Note**: these measures are intended to be used with a report-level *Date Range* filter (or a dedicated RunHistory date dimension) so that the “Window” corresponds to the current filter context.

### OPS RH Runs (Window)
```DAX
OPS RH Runs (Window) =
COUNTROWS ( wh_run )
```

### OPS RH Runs Success (Window)
```DAX
OPS RH Runs Success (Window) =
CALCULATE ( COUNTROWS ( wh_run ), wh_run[run_status] = "SUCCESS" )
```

### Runs Failed
```DAX
Runs Failed =
CALCULATE ( COUNTROWS ( wh_run ), wh_run[run_status] = "FAILED" )
```

### Success Rate
```DAX
Success Rate =
DIVIDE ( [OPS RH Runs Success (Window)], [OPS RH Runs (Window)] )
```

### Avg Duration (min)
```DAX
Avg Duration (min) =
AVERAGEX ( wh_run, DIVIDE ( wh_run[duration_sec], 60 ) )
```

### OPS RH Max Duration (min) (Window)
```DAX
OPS RH Max Duration (min) (Window) =
MAXX ( wh_run, DIVIDE ( wh_run[duration_sec], 60 ) )
```

### OPS RH Rows Processed (Window)
```DAX
OPS RH Rows Processed (Window) =
SUM ( wh_run[rows_processed] )
```

### Critical Failed
```DAX
Critical Failed =
IF ( [Runs Failed] > 0 || [OPS DQ Fail Count] > 0, 1, 0 )
```

---

## OPS / Volume

### OPS Rows Processed
```DAX
OPS Rows Processed =
SUM ( wh_run[rows_processed] )
```

### OPS Rows Processed Color
```DAX
OPS Rows Processed Color =
IF ( [OPS Rows Processed] > 0, "#107C10", "#D13438" )
```

### OPS Rows Source
```DAX
OPS Rows Source =
SELECTEDVALUE ( wh_run[source_system] )
```

---

## Notes
- All color measures are designed for **conditional formatting**.
- Window-based measures rely on **report date filters**.
- This layer is **semantic-only** (no business logic duplication with Gold layer).

---

📌 *This document is portfolio-ready and can be directly embedded in a GitHub repository or client deliverable.*

