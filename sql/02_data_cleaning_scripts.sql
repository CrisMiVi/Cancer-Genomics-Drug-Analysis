/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: 02_data_cleaning_scripts.sql
PURPOSE: Data cleaning for analysis
DATE: March 2026
RATIONALE:
- Entity Resolution: Resolved drug name-ID mismatches using a quality hierarchy (RMSE/Screen Count).
- Pharmacological Capping: Truncated LN_IC50 at Max_Conc to prioritise empirical data over extrapolated noise.
- Sensitivity Classification: Implemented a Z-Score threshold (< -1.5) to isolate the top 6% responders.
*/

----------------------------------------------------------------------------------
-- 1. CLEANING: Cell_line_details_cleaned
----------------------------------------------------------------------------------

/* - Fields with null values: Cancer Type_TCGA and Microsatellite_instability_Status_MSI. Small amount, substitute null values with "Unknown"
   - One record corresponds to the summary; it has been deleted. 
   - The field WES has one single value. It was ignored. 
   - The cleaned table has been saved as Cell_line_details_cleaned.
*/

CREATE OR REPLACE TABLE `PROJECT_ID.CGDA.Cell_line_details_cleaned` AS
SELECT
    COSMIC_identifier
    , Sample_Name
    , WES
    , CAN
    , Gene_Expression
    , Methylation
    , Drug_Response
    , GDSC_Tissue_descriptor1
    , GDSC_Tissue_descriptor2
    -- replaced null values with 'Unknown'
    , COALESCE(`Cancer Type_TCGA`, 'Unknown') AS Cancer_Type_TCGA
    , COALESCE(Microsatellite_instability_Status_MSI, 'Unknown') AS MSI
    , Screen_Medium
    , Growth_Properties
FROM `CGDA.Cell_line_details`
WHERE Sample_Name != 'TOTAL:';


----------------------------------------------------------------------------------
-- 2. CLEANING: GDSC2_cleaned
----------------------------------------------------------------------------------

/* Null values:
        - DATASET, NLME_RESULT_ID and WEBRELEASE have one single value. Both fields were ignored. 
        - TCGA_DESC and PUTATIVE_TARGET had null values. They were replaced with "Unknown".
      
    Data filtering:
        - *Model Fit Reliability (RMSE)*: A high Root Mean Square Error (RMSE) indicates poor curve fitting, which can introduce false positives. I categorised drug-response curves into a Reliability Index:
            - RELIABLE (RMSE < 0.1): High-confidence curve fits.
            - CAUTION (0.1 < RMSE < 0.15): Moderate fits used with oversight.
            - UNRELIABLE (RMSE > 0.15): Excluded to prevent noise from masking biological signals.
        - **Pharmacological Capping (LN_IC50):** Raw IC_50 values often exceed the maximum tested concentration, resulting in unreliable mathematical extrapolations. I added a Capped_(LN_IC50) field, truncating values at the Max_Conc to standardise the representation of resistant cell lines and prioritise empirical data over projected estimates.
        - ***Conservative Sensitivity Classification:** I implemented a strict classification system to isolate the most robust biological signals:
            - SENSITIVE: Defined as an observed LN_IC50 within the experimental range AND a Z_Score < -1.5 (targeting the top 6% of extreme responders).
            - RESISTANT: Defined as any extrapolated LN_IC50 (> Max_Conc) OR a Z_Score > 0.5.
            - INTERMEDIATE: Cell lines in the grey area. 
*/

CREATE OR REPLACE TABLE `PROJECT_ID.CGDA.GDSC2_cleaned` AS
SELECT 
    NLME_CURVE_ID
    , COSMIC_ID
    , CELL_LINE_NAME
    , SANGER_MODEL_ID
    -- substituted null values with "Unknown"
    , COALESCE(TCGA_DESC, 'Unknown') AS TCGA_DESC
    , DRUG_ID
    , DRUG_NAME
    -- substituted null values with "Unkown"
    , COALESCE(PUTATIVE_TARGET, 'Unknown') AS PUTATIVE_TARGET
    , PATHWAY_NAME
    , COMPANY_ID
    , MIN_CONC
    , MAX_CONC
    -- LN_IC50_CAPPED: Truncate at MAX_CONC to remove mathematical extrapolation noise
    , CASE 
        WHEN LN_IC50 > LN(MAX_CONC) THEN LN(MAX_CONC) 
        ELSE LN_IC50 
    END AS LN_IC50_CAPPED
    , LN_IC50
    , AUC
    , RMSE
    , Z_SCORE
    -- SENSITIVITY_CALL: Tiered classification for biomarker discovery
    , CASE 
        WHEN Z_SCORE < -1.5 AND LN_IC50 <= LN(MAX_CONC) THEN 'SENSITIVE'
        WHEN Z_SCORE > 0.5 OR LN_IC50 > LN(MAX_CONC) THEN 'RESISTANT'
        ELSE 'INTERMEDIATE'
    END AS SENSITIVITY_CALL
FROM `CGDA.GDSC2`;


----------------------------------------------------------------------------------
-- 3. CLEANING: TGCA_tissue_classification_cleaned
----------------------------------------------------------------------------------

CREATE OR REPLACE TABLE `PROJECT_ID.CGDA.TGCA_tissue_classification_cleaned` AS
SELECT
    string_field_0 AS TCGA_DESC
    , string_field_1 AS TCGA_name
FROM `CGDA.TGCA_tissue_classification`;


----------------------------------------------------------------------------------
-- 4. CLEANING: screened_compounds_cleaned
-- Resolving Many-to-Many drug name conflicts via Quality-Based Ranking.
----------------------------------------------------------------------------------

/*  Blank values:   
        - There are no null values, but there are blank values. 
        - Blank values: 43 blank values in TARGET and 201 blank values for SYNONYMS. 
        - Will substitute TARGET blank values with "Unknown" and ignore SYNONYMS because there are too many, and this field is not relevant.
        - These changes will be applied to the next cleaning step.
    Duplicated values: 
      Entity Resolution & Drug Metadata Normalisation:
      In the initial dataset, a many-to-many relationship was identified between DRUG_ID and DRUG_NAME (621 unique names across 542 unique IDs). To ensure each therapeutic agent was represented by a single, high-quality primary key for downstream analysis, I implemented a multi-stage deduplication pipeline:
        - Step 1: Assay-Based Filtering: I cross-referenced the compound library against the active GDSC2 screening results. This narrowed the scope to only those drugs with empirical response data, reducing the number of duplicate name-ID pairs from 71 to 9.
        - Step 2: Quality-Driven Selection: For the remaining 9 ambiguous cases, I developed a selection hierarchy to identify the "Golden Record" for each drug name. I prioritised IDs based on:
              - Data Reliability: Selecting the ID with the lowest average RMSE (highest curve-fit quality).
              - Statistical Power: Selecting the ID with the highest Experimental Count (total number of screens).
        - Step 3: Database Normalisation: Using this filtered list of unique DRUG_ID and DRUG_NAME pairs, I generated a cleaned reference table (screened_compounds_clean). This ensured that all subsequent joins remained 1-to-1, preventing data inflation and ensuring consistent drug labelling across the entire study.
    */
 
CREATE OR REPLACE TABLE `PROJECT_ID.CGDA.screened_compounds_cleaned` AS
WITH drug_ranking AS (
    SELECT 
        DRUG_NAME
        , DRUG_ID
        -- Assign row number based on: Lowest RMSE, then most data points
        , ROW_NUMBER() OVER(
            PARTITION BY DRUG_NAME 
            ORDER BY AVG(RMSE) ASC, COUNT(*) DESC
        ) as preference_rank
    FROM `CGDA.GDSC2_cleaned`
    GROUP BY DRUG_NAME, DRUG_ID
),
-- This list will have the 286 unique drug_IDs, and will contain the lowest RMSE and most data points for each DRUG_ID 
best_ranked_table AS (
    SELECT DRUG_ID
    FROM drug_ranking 
    WHERE preference_rank = 1
)
-- Select the cleaned variables for table screened_compounds
SELECT
    comp.DRUG_ID
    , SCREENING_SITE
    , comp.DRUG_NAME
    -- replace blank values
    , CASE WHEN TRIM(`TARGET`) = "" THEN "Unknown" ELSE `TARGET` END AS `TARGET`
    , TARGET_PATHWAY
FROM `CGDA.screened_compounds` AS comp
JOIN best_ranked_table AS ranked ON comp.DRUG_ID = ranked.DRUG_ID;


  


      
