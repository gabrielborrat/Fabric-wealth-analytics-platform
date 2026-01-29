# SM_BUSINESS_Transactions — Catalogue des mesures (DAX)

> **Objectif** : documenter toutes les mesures du modèle **SM_BUSINESS_Transactions** (d’après les dossiers visibles dans le modèle) avec leur **expression DAX**.
>
> **Note** : certaines mesures “Fmt / KPI” référencent d’autres mesures “Base” pour éviter les duplications.

---

## 1) Base

### 1.1 Base\Amounts

#### Base_Amount_Abs_Sum_Total_D
```DAX
Base_Amount_Abs_Sum_Total_D =
COALESCE (
    SUMX ( fact_transactions, ABS ( fact_transactions[amount] ) ),
    0
)
```

#### Base_Amount_Max_D
```DAX
Base_Amount_Max_D =
COALESCE ( MAX ( fact_transactions[amount] ), 0 )
```

#### Base_Amount_Min_D
```DAX
Base_Amount_Min_D =
COALESCE ( MIN ( fact_transactions[amount] ), 0 )
```

#### Base_Amount_Sum_Failed_D
```DAX
Base_Amount_Sum_Failed_D =
COALESCE (
    CALCULATE (
        SUM ( fact_transactions[amount] ),
        fact_transactions[is_success] = FALSE ()
    ),
    0
)
```

#### Base_Amount_Sum_Success_D
```DAX
Base_Amount_Sum_Success_D =
COALESCE (
    CALCULATE (
        SUM ( fact_transactions[amount] ),
        fact_transactions[is_success] = TRUE ()
    ),
    0
)
```

#### Base_Amount_Sum_Total_D
```DAX
Base_Amount_Sum_Total_D =
COALESCE ( SUM ( fact_transactions[amount] ), 0 )
```

---

### 1.2 Base\Counts

#### Base_Card_Count_Distinct_D
```DAX
Base_Card_Count_Distinct_D =
COALESCE ( DISTINCTCOUNT ( fact_transactions[card_key] ), 0 )
```

#### Base_Txn_Count_Failed_D
```DAX
Base_Txn_Count_Failed_D =
COALESCE (
    CALCULATE (
        COUNTROWS ( fact_transactions ),
        fact_transactions[is_success] = FALSE ()
    ),
    0
)
```

#### Base_Txn_Count_Success_D
```DAX
Base_Txn_Count_Success_D =
COALESCE (
    CALCULATE (
        COUNTROWS ( fact_transactions ),
        fact_transactions[is_success] = TRUE ()
    ),
    0
)
```

#### Base_Txn_Count_Total_D
```DAX
Base_Txn_Count_Total_D =
COALESCE ( COUNTROWS ( fact_transactions ), 0 )
```

#### Measure
```DAX
-- Mesure “placeholder” (dossier Counts) : à remplacer/renommer si besoin.
Measure =
BLANK ()
```

---

### 1.3 Base\Detail

> Mesures utilisées typiquement dans la page **Transaction Details** (cartes et table de contexte).

#### Base_Amount_Sum_Detail
```DAX
Base_Amount_Sum_Detail =
[Base_Amount_Sum_Total_D]
```

#### Base_Cards_Active_Detail
```DAX
Base_Cards_Active_Detail =
COALESCE ( DISTINCTCOUNT ( fact_transactions[card_key] ), 0 )
```

#### Base_Merchants_Active_Detail
```DAX
Base_Merchants_Active_Detail =
COALESCE ( DISTINCTCOUNT ( fact_transactions[merchant_id] ), 0 )
```

#### Base_Txn_Count_Detail
```DAX
Base_Txn_Count_Detail =
[Base_Txn_Count_Total_D]
```

#### Base_Txn_Count_Success_Detail
```DAX
Base_Txn_Count_Success_Detail =
[Base_Txn_Count_Success_D]
```

#### Base_Users_Active_Detail
```DAX
Base_Users_Active_Detail =
COALESCE ( DISTINCTCOUNT ( fact_transactions[user_key] ), 0 )
```

---

### 1.4 Base\Risk

#### Base_Card_Count_Active_D
```DAX
Base_Card_Count_Active_D =
COALESCE ( DISTINCTCOUNT ( fact_transactions[card_key] ), 0 )
```

#### Base_Card_Count_DarkWeb_D
```DAX
Base_Card_Count_DarkWeb_D =
COALESCE (
    CALCULATE (
        DISTINCTCOUNT ( dim_card[card_key] ),
        dim_card[card_on_dark_web] = TRUE ()
    ),
    0
)
```

#### Base_Txn_Count_Chip_Not_Used_D
```DAX
Base_Txn_Count_Chip_Not_Used_D =
COALESCE (
    CALCULATE (
        COUNTROWS ( fact_transactions ),
        fact_transactions[is_chip_used] = FALSE ()
    ),
    0
)
```

#### Base_Txn_Count_Chip_Used_D
```DAX
Base_Txn_Count_Chip_Used_D =
COALESCE (
    CALCULATE (
        COUNTROWS ( fact_transactions ),
        fact_transactions[is_chip_used] = TRUE ()
    ),
    0
)
```

---

## 2) Fmt

#### Fmt_Last_Txn_Date
```DAX
Fmt_Last_Txn_Date =
MAX ( dim_date[full_date] )
```

#### Fmt_Selected_Month_Label
```DAX
Fmt_Selected_Month_Label =
VAR _month =
    SELECTEDVALUE ( dim_month[month] )
VAR _year =
    SELECTEDVALUE ( dim_month[year] )
RETURN
IF (
    NOT ISBLANK ( _month ) && NOT ISBLANK ( _year ),
    FORMAT ( DATE ( _year, _month, 1 ), "MMM yyyy" ),
    "All months"
)
```

---

## 3) KPI

### 3.1 KPI\Concentration

#### KPI_MCC_Top1_Share_D
```DAX
KPI_MCC_Top1_Share_D =
VAR _total =
    [Base_Amount_Sum_Total_D]
VAR _top1 =
    MAXX (
        TOPN (
            1,
            SUMMARIZE (
                dim_mcc,
                dim_mcc[mcc_key],
                "Amt", [Base_Amount_Sum_Total_D]
            ),
            [Amt], DESC
        ),
        [Amt]
    )
RETURN
DIVIDE ( _top1, _total, 0 )
```

#### KPI_Merchant_Top1_Share_D
```DAX
KPI_Merchant_Top1_Share_D =
VAR _total =
    [Base_Amount_Sum_Total_D]
VAR _top1 =
    MAXX (
        TOPN (
            1,
            SUMMARIZE (
                fact_transactions,
                fact_transactions[merchant_id],
                "Amt", [Base_Amount_Sum_Total_D]
            ),
            [Amt], DESC
        ),
        [Amt]
    )
RETURN
DIVIDE ( _top1, _total, 0 )
```

---

### 3.2 KPI\Risk

#### KPI_Chip_Adoption_Rate_D
```DAX
KPI_Chip_Adoption_Rate_D =
DIVIDE ( [Base_Txn_Count_Chip_Used_D], [Base_Txn_Count_Total_D], 0 )
```

#### KPI_DarkWeb_Cards
```DAX
KPI_DarkWeb_Cards =
[Base_Card_Count_DarkWeb_D]
```

#### KPI_DarkWeb_Cards_Rate_D
```DAX
KPI_DarkWeb_Cards_Rate_D =
DIVIDE ( [Base_Card_Count_DarkWeb_D], [Base_Card_Count_Active_D], 0 )
```

#### KPI_Failure_Rate_D
```DAX
KPI_Failure_Rate_D =
DIVIDE ( [Base_Txn_Count_Failed_D], [Base_Txn_Count_Total_D], 0 )
```

#### KPI_Success_Rate_D
```DAX
KPI_Success_Rate_D =
DIVIDE ( [Base_Txn_Count_Success_D], [Base_Txn_Count_Total_D], 0 )
```

---

### 3.3 KPI\Spend

#### KPI_Amount_Total_D
```DAX
KPI_Amount_Total_D =
[Base_Amount_Sum_Total_D]
```

#### KPI_Avg_Ticket_Success_D
```DAX
KPI_Avg_Ticket_Success_D =
DIVIDE ( [Base_Amount_Sum_Success_D], [Base_Txn_Count_Success_D], 0 )
```

---

### 3.4 KPI\Volume

#### KPI_Active_Users
```DAX
KPI_Active_Users =
COALESCE ( DISTINCTCOUNT ( fact_transactions[user_key] ), 0 )
```

---

## 4) Checklist d’alignement (recommandé)

- **Colonnes attendues** dans `fact_transactions` : `amount`, `is_success`, `is_chip_used`, `card_key`, `user_key`, `merchant_id`
- **Relation** `fact_transactions[card_key]` → `dim_card[card_key]` active
- **Relation** `fact_transactions[mcc_key]` → `dim_mcc[mcc_key]` active
- **Format** :
  - Amounts : *Currency*
  - Rates : *Percentage*
  - Counts : *Whole number*
