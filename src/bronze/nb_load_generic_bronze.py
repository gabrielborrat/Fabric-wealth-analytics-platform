#!/usr/bin/env python
# coding: utf-8

# ## nb_load_generic_bronze
# 
# null

# In[ ]:


# ==========================================
# PARAMETER CELL (Fabric Notebook)
# ==========================================
# Ces variables seront surchargées par le pipeline.
# valeurs par défaut pour les tests locaux.

LandingPath = "Files/landing/fx/2025-12-01/fx_sample.csv"    # chemin complet du fichier en landing
ExecDate = "2025-12-01"                                      # format 'yyyy-MM-dd'
Entity = "FX"                                                # 'FX' ou 'CUSTOMER' (ou autre plus tard)



# In[ ]:


# ==========================================
# IMPORTS
# ==========================================
from pyspark.sql.functions import (
    col,
    lit,
    upper,
    trim,
    to_date,
    current_timestamp
)
from pyspark.sql import functions as F
import re

# Normalisation de l'entité en UPPER pour faciliter les comparaisons
entity_upper = Entity.upper().strip()

# Helper : conversion d'un nom de colonne en snake_case
def to_snake(name: str) -> str:
    # 1) casser le CamelCase en mots séparés par underscore
    s = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)

    # 2) passer en lower
    s = s.lower()

    # 3) remplacements spécifiques
    s = s.replace('%', 'pct').replace('&', 'and')

    # 4) nettoyer tout ce qui n'est pas alphanumérique en "_"
    s = re.sub(r"[^0-9a-z]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")

    # 5) si ça commence par un chiffre, préfixer
    if len(s) > 0 and s[0].isdigit():
        s = "c_" + s

    return s


# Helper : normalisation des noms de colonnes pour tous les CSV
def normalize_columns(df_raw):
    new_cols = []
    for c in df_raw.columns:
        # Cas particulier fundamentals : première colonne sans nom
        if c == "_c0":
            new_cols.append("unnamed_0")
        else:
            new_cols.append(to_snake(c))
    return df_raw.toDF(*new_cols)

# ticker des stocks et etf derives du nom du fichier
def extract_ticker(source_file: str):
    return F.regexp_extract(F.lit(source_file), r"([^/]+)\.us\.txt$", 1)



# In[ ]:


# ==========================================
# LECTURE DU FICHIER SOURCE (GENERIC)
# ==========================================
# MCC = JSON multi-lignes de type :
# {
#   "5812": "Eating Places and Restaurants",
#   "5921": "Package Stores, Beer, Wine, Liquor",
#   ...
# }
# Tout le reste = CSV classique

if entity_upper == "MCC":
    df_raw = (
        spark.read
             .format("json")
             .option("multiLine", "true")   # important pour un gros objet JSON
             .load(LandingPath)
    )
else:
    df_raw = (
        spark.read
             .format("csv")
             .option("header", "true")
             .option("inferSchema", "true")
             .load(LandingPath)
    )

display(df_raw.limit(10))


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE FX
# ==========================================
def transform_fx(df_raw):
    """
    Transformations Bronze pour les taux FX.
    - colonnes d'entrée (après normalisation) :
      currency, base_currency, currency_name, exchange_rate, date
    """
    df_norm = normalize_columns(df_raw)

    df_fx = (
        df_norm
            .withColumn("currency", F.upper(F.col("currency")))
            .withColumn("date", F.to_date("date"))
            .withColumn("rate_vs_usd", F.col("exchange_rate").cast("double"))
            .select(
                "currency",
                "base_currency",
                "currency_name",
                "rate_vs_usd",
                "date"
            )
    )

    return df_fx


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE CUSTOMER (CHURN)
# ==========================================
def transform_customer(df_raw):
    """
    Transformations Bronze pour le fichier churn.csv.
    Convention :
    - on passe TOUJOURS par normalize_columns() + to_snake()
    - les noms de colonnes sont alignés sur la table bronze_customers_raw
    """

    # 1. Normalisation en snake_case
    df_norm = normalize_columns(df_raw)
    # Exemples après normalisation :
    #   row_number, customer_id, surname, credit_score,
    #   geography, gender, age, tenure, balance,
    #   num_of_products, has_cr_card, is_active_member,
    #   estimated_salary, exited

    # 2. Typage cohérent des colonnes numériques
    df_typed = (
        df_norm
            .withColumn("row_number",        col("row_number").cast("int"))
            .withColumn("customer_id",       col("customer_id").cast("long"))
            .withColumn("credit_score",      col("credit_score").cast("int"))
            .withColumn("age",               col("age").cast("int"))
            .withColumn("tenure",            col("tenure").cast("int"))
            .withColumn("balance",           col("balance").cast("double"))
            .withColumn("num_of_products",   col("num_of_products").cast("int"))
            .withColumn("has_cr_card",       col("has_cr_card").cast("int"))
            .withColumn("is_active_member",  col("is_active_member").cast("int"))
            .withColumn("estimated_salary",  col("estimated_salary").cast("double"))
            .withColumn("exited",            col("exited").cast("int"))
    )

    # 3. Normalisation des colonnes texte (UPPER + TRIM)
    df_clean = (
        df_typed
            .withColumn("surname",   upper(trim(col("surname"))))
            .withColumn("geography", upper(trim(col("geography"))))
            .withColumn("gender",    upper(trim(col("gender"))))
    )

    # 4. SELECT final aligné sur la table bronze_customers_raw
    df_final = df_clean.select(
        "row_number",
        "customer_id",
        "surname",
        "credit_score",
        "geography",
        "gender",
        "age",
        "tenure",
        "balance",
        "num_of_products",
        "has_cr_card",
        "is_active_member",
        "estimated_salary",
        "exited"
    )

    return df_final


# In[ ]:


def load_securities(df_raw):
    """
    Transformations Bronze pour securities.csv
    """
    # Étape 1 : normalisation des noms de colonnes
    df_norm = normalize_columns(df_raw)
    # => ticker_symbol, security, sec_filings, gics_sector, gics_sub_industry,
    #    address_of_headquarters, date_first_added, cik

    # Étape 2 : typage + normalisation
    df_typed = (
        df_norm
            .withColumn("date_first_added", F.to_date("date_first_added"))
            .withColumn("ticker_symbol",    upper(col("ticker_symbol")))
            .withColumn("cik",              col("cik").cast("string"))
    )

    # Étape 3 : SELECT final aligné sur bronze_securities_raw
    df_final = df_typed.select(
        "ticker_symbol",
        "security",
        "sec_filings",
        "gics_sector",
        "gics_sub_industry",
        "address_of_headquarters",
        "date_first_added",
        "cik"
    )

    return df_final


# In[ ]:


def load_fundamentals(df_raw):
    """
    Transformations Bronze pour fundamentals.csv
    Étapes :
    1. Normalisation des noms de colonnes (normalize_columns + to_snake)
    2. Typage spécifique :
       - unnamed_0 -> BIGINT (long)
       - period_ending -> DATE
    """

    # Étape 1 : normalisation des noms de colonnes
    df_norm = normalize_columns(df_raw)
    # => unnamed_0, ticker_symbol, period_ending, ...

    # Étape 2 : typage ciblé
    df_typed = df_norm

    if "unnamed_0" in df_typed.columns:
        df_typed = df_typed.withColumn("unnamed_0", col("unnamed_0").cast("long"))

    if "period_ending" in df_typed.columns:
        df_typed = df_typed.withColumn("period_ending", F.to_date("period_ending"))

    # Étape 3 : SELECT final aligné sur bronze_fundamentals_raw
    df_final = df_typed.select(
        "unnamed_0",
        "ticker_symbol",
        "period_ending",
        "accounts_payable",
        "accounts_receivable",
        "add_l_income_expense_items",
        "after_tax_roe",
        "capital_expenditures",
        "capital_surplus",
        "cash_ratio",
        "cash_and_cash_equivalents",
        "changes_in_inventories",
        "common_stocks",
        "cost_of_revenue",
        "current_ratio",
        "deferred_asset_charges",
        "deferred_liability_charges",
        "depreciation",
        "earnings_before_interest_and_tax",
        "earnings_before_tax",
        "effect_of_exchange_rate",
        "equity_earnings_loss_unconsolidated_subsidiary",
        "fixed_assets",
        "goodwill",
        "gross_margin",
        "gross_profit",
        "income_tax",
        "intangible_assets",
        "interest_expense",
        "inventory",
        "investments",
        "liabilities",
        "long_term_debt",
        "long_term_investments",
        "minority_interest",
        "misc_stocks",
        "net_borrowings",
        "net_cash_flow",
        "net_cash_flow_operating",
        "net_cash_flows_financing",
        "net_cash_flows_investing",
        "net_income",
        "net_income_adjustments",
        "net_income_applicable_to_common_shareholders",
        "net_income_cont_operations",
        "net_receivables",
        "non_recurring_items",
        "operating_income",
        "operating_margin",
        "other_assets",
        "other_current_assets",
        "other_current_liabilities",
        "other_equity",
        "other_financing_activities",
        "other_investing_activities",
        "other_liabilities",
        "other_operating_activities",
        "other_operating_items",
        "pre_tax_margin",
        "pre_tax_roe",
        "profit_margin",
        "quick_ratio",
        "research_and_development",
        "retained_earnings",
        "sale_and_purchase_of_stock",
        "sales_general_and_admin",
        "short_term_debt_current_portion_of_long_term_debt",
        "short_term_investments",
        "total_assets",
        "total_current_assets",
        "total_current_liabilities",
        "total_equity",
        "total_liabilities",
        "total_liabilities_and_equity",
        "total_revenue",
        "treasury_stock",
        "for_year",
        "earnings_per_share",
        "estimated_shares_outstanding"
    )

    return df_final


# In[ ]:


def load_prices(df_raw):
    """
    Transformations Bronze pour prices.csv
    """
    df_norm = normalize_columns(df_raw)

    df_typed = (
        df_norm
            .withColumn("date",   F.to_timestamp("date"))
            .withColumn("open",   col("open").cast("double"))
            .withColumn("close",  col("close").cast("double"))
            .withColumn("low",    col("low").cast("double"))
            .withColumn("high",   col("high").cast("double"))
            .withColumn("volume", col("volume").cast("double"))
    )

    df_final = df_typed.select(
        "date",
        "symbol",
        "open",
        "close",
        "low",
        "high",
        "volume"
    )

    return df_final


# In[ ]:


def load_prices_split_adjusted(df_raw):
    """
    Transformations Bronze pour prices-split-adjusted.csv
    """
    df_norm = normalize_columns(df_raw)

    df_typed = (
        df_norm
            .withColumn("date",   F.to_timestamp("date"))
            .withColumn("open",   col("open").cast("double"))
            .withColumn("close",  col("close").cast("double"))
            .withColumn("low",    col("low").cast("double"))
            .withColumn("high",   col("high").cast("double"))
            .withColumn("volume", col("volume").cast("double"))
    )

    df_final = df_typed.select(
        "date",
        "symbol",
        "open",
        "close",
        "low",
        "high",
        "volume"
    )

    return df_final


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE ETF
# ==========================================
def load_etf(df_raw):
    """
    Transformations Bronze pour les fichiers ETF au format OHLCV.
    Colonnes attendues après normalize_columns():
      ticker, date, open, high, low, close, volume, open_int
    La colonne ticker est lue directement depuis le fichier.
    """
    df_norm = normalize_columns(df_raw)

    df_typed = (
        df_norm
            # ticker en snake_case déjà présent après normalize_columns()
            .withColumn("ticker", upper(trim(col("ticker"))))
            .withColumn("date",   F.to_date("date", "yyyy-MM-dd"))
            .withColumn("open",   col("open").cast("double"))
            .withColumn("high",   col("high").cast("double"))
            .withColumn("low",    col("low").cast("double"))
            .withColumn("close",  col("close").cast("double"))
            .withColumn("volume",   col("volume").cast("bigint"))
            .withColumn("open_int", col("open_int").cast("bigint"))
    )

    df_final = df_typed.select(
        "ticker",
        "date",
        "open",
        "high",
        "low",
        "close",
        "volume",
        "open_int"
    )

    return df_final


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE STOCK
# ==========================================
def load_stock(df_raw):
    """
    Transformations Bronze pour les fichiers STOCK au format OHLCV.
    Colonnes attendues après normalize_columns():
      ticker, date, open, high, low, close, volume, open_int
    La colonne ticker est lue directement depuis le fichier.
    """
    df_norm = normalize_columns(df_raw)

    df_typed = (
        df_norm
            .withColumn("ticker", upper(trim(col("ticker"))))
            .withColumn("date",   F.to_date("date", "yyyy-MM-dd"))
            .withColumn("open",   col("open").cast("double"))
            .withColumn("high",   col("high").cast("double"))
            .withColumn("low",    col("low").cast("double"))
            .withColumn("close",  col("close").cast("double"))
            .withColumn("volume",   col("volume").cast("bigint"))
            .withColumn("open_int", col("open_int").cast("bigint"))
    )

    df_final = df_typed.select(
        "ticker",
        "date",
        "open",
        "high",
        "low",
        "close",
        "volume",
        "open_int"
    )

    return df_final


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE CARDS
# ==========================================
def load_cards(df_raw):
    """
    Transformations Bronze pour cards_data.csv.
    Colonnes attendues après normalize_columns():
      id, client_id, card_brand, card_type, card_number,
      expires, cvv, has_chip, num_cards_issued,
      credit_limit, acct_open_date, year_pin_last_changed,
      card_on_dark_web
    """
    df_norm = normalize_columns(df_raw)

    df_typed = (
        df_norm
            # Identifiants et numériques
            .withColumn("id",                col("id").cast("bigint"))
            .withColumn("client_id",         col("client_id").cast("bigint"))
            .withColumn("num_cards_issued",  col("num_cards_issued").cast("int"))
            .withColumn("year_pin_last_changed", col("year_pin_last_changed").cast("int"))
            # Texte / catégories normalisées
            .withColumn("card_brand",  upper(trim(col("card_brand"))))
            .withColumn("card_type",   upper(trim(col("card_type"))))
            .withColumn("has_chip",    upper(trim(col("has_chip"))))
            .withColumn("card_on_dark_web", upper(trim(col("card_on_dark_web"))))
            # Numéros sensibles conservés en string
            .withColumn("card_number", col("card_number").cast("string"))
            .withColumn("cvv",         col("cvv").cast("string"))
            # Limite de crédit : suppression de "$" puis cast en double
            .withColumn(
                "credit_limit",
                F.regexp_replace("credit_limit", r"[^0-9.]", "").cast("double")
            )
            # Dates : on reste en string en Bronze (MM/YYYY, MM/YYYY)
            .withColumn("expires",        col("expires").cast("string"))
            .withColumn("acct_open_date", col("acct_open_date").cast("string"))
    )

    df_final = df_typed.select(
        "id",
        "client_id",
        "card_brand",
        "card_type",
        "card_number",
        "expires",
        "cvv",
        "has_chip",
        "num_cards_issued",
        "credit_limit",
        "acct_open_date",
        "year_pin_last_changed",
        "card_on_dark_web"
    )

    return df_final


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE USERS
# ==========================================
def load_users(df_raw):
    """
    Transformations Bronze pour users_data.csv.
    Colonnes attendues après normalize_columns():
      id, current_age, retirement_age, birth_year, birth_month,
      gender, address, latitude, longitude,
      per_capita_income, yearly_income, total_debt,
      credit_score, num_credit_cards
    """
    df_norm = normalize_columns(df_raw)

    df_typed = (
        df_norm
            # Identifiants & âges
            .withColumn("id",             col("id").cast("bigint"))
            .withColumn("current_age",    col("current_age").cast("int"))
            .withColumn("retirement_age", col("retirement_age").cast("int"))
            .withColumn("birth_year",     col("birth_year").cast("int"))
            .withColumn("birth_month",    col("birth_month").cast("int"))
            # Coordonnées
            .withColumn("latitude",  col("latitude").cast("double"))
            .withColumn("longitude", col("longitude").cast("double"))
            # Texte
            .withColumn("gender",  upper(trim(col("gender"))))
            .withColumn("address", trim(col("address")))
            # Montants monétaires : suppression de "$" puis cast
            .withColumn(
                "per_capita_income",
                F.regexp_replace("per_capita_income", r"[^0-9.]", "").cast("double")
            )
            .withColumn(
                "yearly_income",
                F.regexp_replace("yearly_income", r"[^0-9.]", "").cast("double")
            )
            .withColumn(
                "total_debt",
                F.regexp_replace("total_debt", r"[^0-9.]", "").cast("double")
            )
            # Score & nombre de cartes
            .withColumn("credit_score",     col("credit_score").cast("int"))
            .withColumn("num_credit_cards", col("num_credit_cards").cast("int"))
    )

    df_final = df_typed.select(
        "id",
        "current_age",
        "retirement_age",
        "birth_year",
        "birth_month",
        "gender",
        "address",
        "latitude",
        "longitude",
        "per_capita_income",
        "yearly_income",
        "total_debt",
        "credit_score",
        "num_credit_cards"
    )

    return df_final


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE TRANSACTIONS
# ==========================================
def load_transactions(df_raw):
    """
    Transformations Bronze pour transactions_data.csv.
    Colonnes attendues (header CSV) :
      id, date, client_id, card_id, amount, use_chip,
      merchant_id, merchant_city, merchant_state, zip, mcc, errors
    """

    # 1. Normalisation éventuelle (garantie snake_case)
    df_norm = normalize_columns(df_raw)

    # 2. Typage & nettoyage
    df_typed = (
        df_norm
            # Identifiants
            .withColumn("id",          col("id").cast("bigint"))
            .withColumn("client_id",   col("client_id").cast("bigint"))
            .withColumn("card_id",     col("card_id").cast("bigint"))
            .withColumn("merchant_id", col("merchant_id").cast("bigint"))

            # Date/heure de la transaction
            .withColumn("date", F.to_timestamp("date"))

            # Montant : suppression de "$", "," etc. avant cast en DOUBLE
            .withColumn(
                "amount",
                F.regexp_replace("amount", r"[^0-9\.\-]", "").cast("double")
            )

            # Champs texte : normalisation
            .withColumn("use_chip",       upper(trim(col("use_chip"))))
            .withColumn("merchant_city",  upper(trim(col("merchant_city"))))
            .withColumn("merchant_state", upper(trim(col("merchant_state"))))

            # ZIP + codes
            .withColumn("zip",    trim(col("zip").cast("string")))
            .withColumn("mcc",    col("mcc").cast("int"))
            .withColumn("errors", col("errors").cast("int"))
    )

    # 3. SELECT final aligné sur la table bronze_transactions_raw
    df_final = df_typed.select(
        "id",
        "date",
        "client_id",
        "card_id",
        "amount",
        "use_chip",
        "merchant_id",
        "merchant_city",
        "merchant_state",
        "zip",
        "mcc",
        "errors"
    )

    return df_final


# In[ ]:


# ==========================================
# TRANSFORMATION BRONZE MCC
# ==========================================
def load_mcc(df_raw):
    """
    Transformations Bronze pour le fichier MCC JSON.
    JSON attendu :
      {
        "5812": "Eating Places and Restaurants",
        "5921": "Package Stores, Beer, Wine, Liquor",
        ...
      }

    df_raw : une seule ligne, avec une colonne par code MCC ("5812", "5921", ...)
    On convertit ça en lignes : (mcc, mcc_description).
    """

    cols = df_raw.columns

    df_map = df_raw.select(
        F.explode(
            F.map_from_arrays(
                F.array(*[F.lit(c) for c in cols]),     # clés = codes MCC (string)
                F.array(*[F.col(c) for c in cols])      # valeurs = descriptions
            )
        ).alias("mcc", "mcc_description")
    )

    df_typed = (
        df_map
            .withColumn("mcc",           F.col("mcc").cast("int"))
            .withColumn("mcc_description", F.trim(F.col("mcc_description")))
    )

    # SELECT final aligné sur bronze_mcc_raw
    df_final = df_typed.select(
        "mcc",
        "mcc_description"
    )

    return df_final


# In[ ]:


# ==========================================
# DISPATCHER SELON ENTITY + COLONNES TECHNIQUES
# ==========================================

if entity_upper == "FX":
    df_core = transform_fx(df_raw)
    target_table = "bronze_fx_raw"

elif entity_upper == "CUSTOMER":
    df_core = transform_customer(df_raw)
    target_table = "bronze_customers_raw"

elif entity_upper == "SECURITIES":
    df_core = load_securities(df_raw)
    target_table = "bronze_securities_raw"

elif entity_upper == "FUNDAMENTALS":
    df_core = load_fundamentals(df_raw)
    target_table = "bronze_fundamentals_raw"

elif entity_upper == "PRICES":
    df_core = load_prices(df_raw)
    target_table = "bronze_prices_raw"

elif entity_upper == "PRICES_SPLIT_ADJUSTED":
    df_core = load_prices_split_adjusted(df_raw)
    target_table = "bronze_prices_split_adjusted_raw"

elif entity_upper == "ETF":
    df_core = load_etf(df_raw)
    target_table = "bronze_etf_raw"

elif entity_upper == "STOCK":
    df_core = load_stock(df_raw)
    target_table = "bronze_stock_raw"


elif entity_upper == "CARD":
    df_core = load_cards(df_raw)
    target_table = "bronze_card_raw"

elif entity_upper == "USER":
    df_core = load_users(df_raw)
    target_table = "bronze_user_raw"

elif entity_upper == "TRANSACTION":
    df_core = load_transactions(df_raw)
    target_table = "bronze_transactions_raw"

elif entity_upper == "MCC":
    df_core = load_mcc(df_raw)
    target_table = "bronze_mcc_raw"

else:
    # Fallback générique : on ne transforme presque pas, mais on loggue quand même
    # Utile si ajout d'autres entités plus tard.
    df_core = df_raw
    target_table = f"bronze_{entity_upper.lower()}_raw"


# Ajout des colonnes techniques communes
df_bronze = (
    df_core
        # Source file : ici on garde le chemin complet tel qu'il arrive du pipeline
        .withColumn("source_file",   lit(LandingPath))
        # Ingestion_date : date logique du run (ExecDate)
        .withColumn("ingestion_date", to_date(lit(ExecDate), "yyyy-MM-dd"))
        # Ingestion_ts : timestamp technique
        .withColumn("ingestion_ts",  current_timestamp())
        # Entity : pour retrouver facilement l'origine
        .withColumn("entity",        lit(entity_upper))
)

display(df_bronze.limit(10))


# In[ ]:


# ==========================================
# ÉCRITURE DANS LA TABLE BRONZE
# ==========================================
# IMPORTANT :
# - Le notebook doit être lié au Lakehouse `lh_wm_core`.
# - Les tables seront créées automatiquement en Delta dans ce Lakehouse.

(
    df_bronze
        .write
        .mode("append")
        .format("delta")
        .saveAsTable(target_table)
)

