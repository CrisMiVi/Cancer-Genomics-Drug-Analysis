# Data Cleaning & Transformation Log

**Project:** Cancer Genomics & Drug Sensitivity Analysis (GDSC)  
**Status:** Phase 1 (Data Engineering & Warehouse Construction) Complete  

---

## 1. Overview of Data Pipeline
The objective of this phase was to consolidate four disparate data sources into a high-integrity relational model. The primary challenge involved resolving many-to-many relationships in drug identifiers and handling right-censored experimental values. 

The pipeline is organised into three sequential stages: Validation, Cleaning, and Integration.

---

## 2. Phase 1: Data Validation & Auditing
**Reference Script:** [`sql/01_data_validation_scripts.sql`](./sql/01_data_validation_scripts.sql)

Before transformation, a non-destructive audit was performed to identify structural risks:
* **PK Integrity:** Verified uniqueness for `COSMIC_ID` and `DRUG_ID`. 
* **Null Distribution:** Identified significant missingness in `TCGA_DESC` (1,067 records) and `PUTATIVE_TARGET` (27,155 records), necessitating an imputation strategy to prevent data loss during joins.
* **Redundancy:** Flagged the `WES` and `WEBRELEASE` columns as single-value constants; these were excluded from the final model to reduce dimensionality.

---

## 3. Phase 2: Table-Specific Cleaning & Engineering
**Reference Script:** [`sql/02_data_cleaning_scripts.sql`](./sql/02_data_cleaning_scripts.sql)

### Cell Line Metadata
* **Outlier Removal:** Identified and removed a summary row labelled "TOTAL:" to prevent skewing statistical aggregates.
* **Imputation:** Missing TCGA and MSI values were imputed as "Unknown" to maintain sample size for non-genomic drug response analysis.

### Screened Compounds (Entity Resolution)
* **Conflict Resolution:** Resolved a "Many-to-Many" collision where 71 drug names were associated with multiple IDs.
* **Quality Hierarchy:** Implemented a selection logic that prioritized IDs based on the lowest Average RMSE (reliability) and highest screening count (statistical power).

### Feature Engineering
* **LN_IC50_CAPPED:** Created to handle Right-Censorship. Values exceeding the `MAX_CONC` were capped at $LN(MAX\_CONC)$ to prevent the predictive model from learning from extrapolated mathematical noise.
* **SENSITIVITY_CALL**: Developed a tiered classification system:
    * **SENSITIVE:** $Z < -1.5$ (Top 6% responders) AND within tested dose range.
    * **RESISTANT:** $Z > 0.5$ or exceeding tested dose range.

---

## 4. Phase 3: Final Warehouse Integration
**Reference Script:** [`sql/03_fct_drug_sensitivity_merge.sql`](./sql/03_fct_drug_sensitivity_merge.sql)

* **Architecture:** Developed the `fct_drug_sensitivity` Master Table using a Star Schema approach.
* **Referential Integrity:** Utilised `INNER JOIN` logic between drug responses and cell line metadata to ensure every record in the final fact table contains a complete genomic profile.
* **Denormalisation:** Integrated tissue site and histology data directly into the fact table to optimise query performance for Looker Studio visualisation.

<img width="451" height="687" alt="image" src="https://github.com/user-attachments/assets/ac33480a-cc1b-4e42-8265-bb01b62b8ea8" />
