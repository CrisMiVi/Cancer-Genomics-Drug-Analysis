
# Data Dictionary: Cancer Genomics & Drug Sensitivity (GDSC)

This document serves as the formal schema definition for the `fct_drug_sensitivity` (merged) table. It provides descriptions and the analytical significance of each feature to ensure data transparency for clinical and technical stakeholders.

---

## 1. Biological & Tissue Metadata
*Dimensions describing the cancer cell line models.*

| Column Name | Description | Analytical Significance |
| :--- | :--- | :--- |
| **COSMIC_ID** | Unique identifier for the cell line from the COSMIC database. | The Primary Key for biological entities; ensures referential integrity across genomic datasets. |
| **SAMPLE_NAME** | Common name of the cancer cell line (e.g., A549, MCF7). | Essential for human-readable reporting and cross-referencing with existing oncology literature. |
| **TCGA_LABEL** | Short-code classification (The Cancer Genome Atlas) for cancer type. | Standardises the dataset for clinical relevance; allows for comparison with patient-derived tumour data. |
| **TCGA_DESC** | Full-text description of the TCGA cancer classification. | Provides high-level grouping for Tissue-Stratified Analysis (e.g., Lung, Breast, Colon). |
| **PRIMARY_SITE** | The anatomical location where the cancer first originated. | Used to determine if drug sensitivity is organ-dependent or systemic. |
| **HISTOLOGY_TYPE** | Pathological classification of the tumour (e.g., Carcinoma, Melanoma). | Critical for identifying lineage-specific drug vulnerabilities at a cellular level. |
| **CNA** | Copy Number Alterations; data on gene deletions or amplifications. | Identifies genomic structural changes that drive drug resistance or extreme sensitivity. |
| **GENE_EXPRESSION** | Quantified activity levels of specific genes within the cell line. | Often the strongest predictor of drug response; identifies active biological "engines." |
| **METHYLATION** | Data on DNA chemical modifications (epigenetic silencing). | Helps identify "silenced" genes that may bypass a drug's molecular mechanism. |
| **MSI** | Microsatellite Instability Status (MSS vs. MSI-H). | A vital biomarker for Genomic Instability; MSI-H lines often show unique responses to specific inhibitors. |
| **GROWTH_PROPERTIES** | Characteristics of cell culture growth (e.g., Adherent, Suspension). | Used as a confounding variable check to ensure growth method does not bias drug uptake. |
| **SCREEN_MEDIUM** | The growth medium used during the experimental assay. | Important for experimental control; ensures response is not an artefact of nutrient availability. |

---

## 2. Drug & Treatment Metadata
*Dimensions describing the therapeutic compounds.*

| Column Name | Description | Analytical Significance |
| :--- | :--- | :--- |
| **DRUG_ID** | Unique numeric identifier for the specific drug compound. | The Primary Key for therapeutics; ensures precision when different vendors use similar generic names. |
| **DRUG_NAME** | The common or chemical name of the therapeutic agent. | Necessary for stakeholder-facing dashboards and identifying well-known clinical inhibitors. |
| **DRUG_TARGET** | The molecular protein(s) the drug is designed to inhibit. | Used to validate if the drug is successfully engaging its intended "biological lock." |
| **DRUG_TARGET_PATHWAY** | The biological signalling pathway targeted by the drug. | Allows for Pathway-Level Aggregation (e.g., analysing the collective performance of all PI3K inhibitors). |

---

## 3. Response Metrics & Quality Control
*The target variables and experimental boundaries used to measure success.*

| Column Name | Description | Analytical Significance |
| :--- | :--- | :--- |
| **LN_IC50_CAPPED** | Natural log of the $IC_{50}$, truncated at the maximum tested dosage. | Primary Target Variable. Standardises potency while removing noise from unreliable extrapolations beyond the tested range. |
| **Z_SCORE** | Standardised score of the drug response (Standard Deviations). | Normalises sensitivity; allows for comparison of a cell line's performance relative to its peers. |
| **SENSITIVITY_CALL** | Categorical label (SENSITIVE, INTERMEDIATE, RESISTANT). | Engineered for Biomarker Enrichment Studies; converts continuous data into actionable biological classes. |
| **AUC** | Area Under the Curve of the dose-response relationship. | Represents Total Efficacy; a robust measure for drugs that do not achieve 100% cell inhibition. |
| **RMSE** | Root Mean Square Error of the fitted dose-response curve. | Data Quality Metric. Used to filter out "noisy" experiments where mathematical fit was poor ($RMSE > 0.15$). |
| **MIN_CONC** | Minimum concentration of the drug used in the assay. | Defines the lower boundary of the experimental testing window. |
| **MAX_CONC** | Maximum concentration of the drug used in the assay. | Defines the upper boundary; critical for identifying "Censored" resistant data points. |

<img width="451" height="688" alt="image" src="https://github.com/user-attachments/assets/f2635a47-c15b-4562-beb0-86c3b9b19861" />




























