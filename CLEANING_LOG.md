# 🛠 Data Cleaning & Transformation Log

**Project:** Cancer Genomics & Drug Sensitivity Analysis (GDSC)  
**Status:** Phase 1 (Data Engineering) Complete  

---

## 1. Overview of Data Pipeline
The objective of this phase was to consolidate four disparate data sources into a high-integrity relational model. The primary challenge involved resolving many-to-many relationships in drug identifiers and handling right-censored experimental values.

## 2. Table-Specific Cleaning Actions

### 🧬 Cell Line Metadata (`Cell_line_details`)
* **Outlier Removal:** Identified and removed a summary row labeled "TOTAL:" to prevent skewing statistical aggregates.
* **Imputation:** * Identified 176 missing values in `Cancer Type_TCGA` and 16 in `MSI_Status`. 
    * **Decision:** Imputed as `"Unknown"` rather than dropping rows to maintain sample size.

### 💊 Screened Compounds (`screened_compounds`)
* **Conflict Resolution:** Resolved a "Many-to-Many" collision where 71 `DRUG_NAME` entries were associated with multiple `DRUG_ID`s.
* **Logic:** Implemented **Quality-Based Selection**. For drugs with multiple IDs, the ID with the **lowest Average RMSE** and **highest screening count** was retained. [See SQL script here](./sql/clean_compounds.sql).

### 📊 Drug Response Data (`GDSC2`)
* **Reliability Categorization:** Engineered a `RELIABILITY` flag based on RMSE:
    * **Reliable:** < 0.1
    * **Caution:** 0.1 - 0.15
    * **Unreliable:** > 0.15

---

## 3. Advanced Feature Engineering
* **LN_IC50_CAPPED:** Created to handle right-censorship. Values exceeding the `MAX_CONC` were capped at $LN(MAX\_CONC)$ to prevent model training on extrapolated noise.
* **SENSITIVITY_CALL:** Developed a tiered classification system:
    * **SENSITIVE:** $Z < -1.5$ (Top 6% responders).
    * **RESISTANT:** $Z > 0.5$ or exceeding tested dose range.
