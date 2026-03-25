/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: Validation steps
PURPOSE: Validating uniqueness and referential integrity across raw datasets.
DATE: March 2026
*/


-- AUDIT 1: Testing uniqueness of COSMIC_ID in Cell Line Details
-- If row_count > 0, the Primary Key is compromised. 
    
  SELECT
    COSMIC_identifier
    , COUNT(*) AS row_count
  FROM CGDA.Cell_line_details
  GROUP BY 1
  HAVING row_count > 1;

-- AUDIT 2: Testing uniqueness of DRUG_ID in Screened Compounds
  SELECT
    DRUG_ID,
    , COUNT(*) AS row_count
  FROM CGDA.screened_compounds
  GROUP BY 1
  HAVING row_count > 1;

-- AUDIT 3: Checking for Orphaned Records (Referential Integrity)
-- Ensure all COSMIC_IDs in the response data exist in the metadata table.
  
  SELECT DISTINCT 
      GDSC2.COSMIC_ID
  FROM CGDA.GDSC2 AS GDSC2
  LEFT JOIN `CGDA.Cell_line_details AS cell
  ON GDSC2.COSMIC_ID = cell.COSMIC_identifier
  WHERE cell.COSMIC_identifier IS NULL;


-----------------------------------------------------------------------------------------------
--- 1. TABLE: COSMIC_tissue_classification ---
-----------------------------------------------------------------------------------------------

--1A. AUDIT: Primary Key (PK) COSMIC_ID
  
    SELECT
      COSMIC_ID
      ,COUNT(*) AS row_count
    FROM COSMIC_tissue_classification
    GROUP BY CGDA.COSMIC_ID
    HAVING row_count > 1;


-- 2A. AUDIT: PK COSMIC_ID 
    
    SELECT
      COSMIC_identifier
      , COUNT(*) AS row_count
    FROM CGDA.Cell_line_details
    GROUP BY COSMIC_identifier
    HAVING row_count > 1;


      
-----------------------------------------------------------------------------------------------
--- 3. TABLE: GDSC2 ---
-----------------------------------------------------------------------------------------------

-- 2A. AUDIT: PK COSMIC_ID and DRUG_ID
  
  SELECT
    COSMIC_ID
    , DRUG_ID
    , COUNT(*) AS row_count
  FROM CGDA.GDSC2
  GROUP BY 
    COSMIC_ID
    , DRUG_ID
  HAVING row_count > 1 

-- 3B. Nulls values: 
    /* 
      - DATASET, NLME_RESULT_ID and WEBRELEASE have one single value. Both fields were ignored. 
      - TCGA_DESC and PUTATIVE_TARGET had null values. They were replaced with "unkown".
    */
  ---> TCGA_DESC has 1067/ 242036 null values, substitute them with 'unkown'.
  SELECT COUNT(*)
  FROM CGDA.GDSC2
  WHERE TCGA_DESC IS NULL 

  ---> PUTATIVE_TARGET has 27155/ 242036 null values, substitute them with 'unkown'.
  SELECT COUNT(*)
  FROM CGDA.GDSC2
  WHERE PUTATIVE_TARGET IS NULL 

-- 3C. Data filtering:
    /* 
      - Model Fit Reliability (RMSE): High Root Mean Square Error (RMSE) indicates poor curve fitting, which can introduce false positives. I categorized drug-response curves into a Reliability Index:
            - RELIABLE (RMSE < 0.1): High-confidence curve fits.
            - CAUTION (0.1 < RMSE < 0.15): Moderate fits used with oversight.
            - UNRELIABLE (RMSE > 0.15): Excluded to prevent noise from masking biological signals.
      
      - **Pharmacological Capping (LN_IC50):** Raw IC_50 values often exceed the maximum tested concentration , resulting in unreliable mathematical extrapolations. I added a Capped_(LN_IC50) field, truncating values at the Max_Conc to standardise the representation of resistant cell lines and prioritise empirical data over projected estimates.

      - ***Conservative Sensitivity Classification:** I implemented a strict classification system to isolate the most robust biological signals:
            - SENSITIVE: Defined as an observed LN_IC50 within the experimental range AND a Z_Score < -1.5 (targeting the top 6% of extreme responders).
            - RESISTANT: Defined as any extrapolated LN_IC50 (> Max_Conc) OR a Z_Score > 0.5.
            - INTERMEDIATE: Cell lines in the gray area. 

      -  Saved the table as GDSC2_cleaned
 */
    CREATE OR REPLACE TABLE CGDA.GDSC2_cleaned AS
    SELECT 
      NLME_CURVE_ID 
      , COSMIC_ID
      , CELL_LINE_NAME
      , SANGER_MODEL_ID
    -- substituted null values by "uknown"
      , COALESCE(TCGA_DESC, 'unknown') AS TCGA_DESC,
      , DRUG_ID
      , DRUG_NAME
    -- substituted null values by "uknown"
      , COALESCE(PUTATIVE_TARGET, 'unknown') AS PUTATIVE_TARGET,
      , PATHWAY_NAME
      , COMPANY_ID
      , MIN_CONC
      , MAX_CONC
    -- LN_IC50_CAPPED: Truncate at MAX_CONC to remove mathematical extrapolation noise
      ,CASE 
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
    FROM CGDA.GDSC2 


-----------------------------------------------------------------------------------------------
--- 4. TABLE: TGCA_tissue_classification ---
-----------------------------------------------------------------------------------------------

-- 4A. Add labels to the metrics
  SELECT
  string_field_0 AS TCGA_DESC
  , string_field_1 AS TCGA_name
  FROM CGDA.TGCA_tissue_classification
      

-----------------------------------------------------------------------------------------------
--- 5. TABLE: SCREENED_COMPOUNDS ---
-----------------------------------------------------------------------------------------------

-- 5A. AUDIT: PK DRUG_ID
  SELECT 
    DRUG_ID
    , COUNT(*) AS drug_ID_count
  FROM CGDA.screened_compounds
  GROUP BY DRUG_ID
  HAVING drug_ID_count > 1; 

-- 5B. Blank values: 
    /*    
      - There are no null values, but there are blank values. 
      - Blank values: 43 blank values in TARGET and 201 blank values for SYNONYMS. 
      - Will substitute TARGET blank values with "unkown" and ignore SYNONYMS because they are too many and this field is not relevant.
      - This changes will be applied to the next cleaning step.
    */

-- 5C. Duplicated values: 
    /*
      Entity Resolution & Drug Metadata Normalisation:
      In the initial dataset, a many-to-many relationship was identified between DRUG_ID and DRUG_NAME (621 unique names across 542 unique IDs). To ensure each therapeutic agent was represented by a single, high-quality primary key for downstream analysis, I implemented a multi-stage deduplication pipeline:
          - Step 1: Assay-Based Filtering: I cross-referenced the compound library against the active GDSC2 screening results. This narrowed the scope to only those drugs with empirical response data, reducing the number of duplicate name-ID pairs from 71 to 9.
          - Step 2: Quality-Driven Selection: For the remaining 9 ambiguous cases, I developed a selection hierarchy to identify the "Golden Record" for each drug name. I prioritized IDs based on:
              - Data Reliability: Selecting the ID with the lowest average RMSE (highest curve-fit quality).
              - Statistical Power: Selecting the ID with the highest Experimental Count (total number of screens).
          - Step 3: Database Normalization: Using this filtered list of unique DRUG_ID and DRUG_NAME pairs, I generated a cleaned reference table (screened_compounds_clean). This ensured that all subsequent joins remained 1-to-1, preventing data inflation and ensuring consistent drug labeling across the entire study.
    */

  WITH drug_ranking AS (
    SELECT 
        DRUG_NAME
        ,DRUG_ID
        -- Assign row number based on: Lowest RMSE, then most data points
        ,ROW_NUMBER() OVER(
            PARTITION BY DRUG_NAME 
            ORDER BY AVG(RMSE) ASC, COUNT(*) DESC
        ) as preference_rank
    FROM CGDA.GDSC2_cleaned
    GROUP BY DRUG_NAME, DRUG_ID
  ),
  
    -- This list will have the 286 unique drug_IDs, and will contain the lowest RMSE and most data points for each DRUG_ID 
  best_ranked_table AS(
    SELECT 
      DRUG_ID
    FROM drug_ranking 
    WHERE preference_rank = 1
  )
  
    -- Select the cleaned variables for table screened_compounds
  CREATE OR REPLACE TABLE CGDA.screened_compounds_cleaned AS
  SELECT
    comp.DRUG_ID
    , SCREENING_SITE
    , DRUG_NAME
    --- replaced the balnk values from step 5B
    , CASE WHEN TRIM(`TARGET`) = "" THEN "unknown" ELSE `TARGET` END AS `TARGET`
    , TARGET_PATHWAY
  FROM CGDA.screened_compounds AS comp
  JOIN best_ranked_table AS ranked
  ON comp.DRUG_ID = ranked.DRUG_ID
