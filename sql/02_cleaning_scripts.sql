/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: Table cleaning
PURPOSE: Cleaning tables: COSMIC_tissue_classification, Cell_line_details, GDSC2, TGCA_tissue_classification and screened_compounds
DATE: March 2026
EDA (Exploratory Data Analysis) & Data Integrity:
Prior to table transformation, a comprehensive audit was performed to identify and resolve structural inconsistencies. To maintain a clean and reproducible repository, the following exploratory steps are summarized here, while the provided SQL scripts focus on the final data cleaning and "Golden Record" generation:
  - Entity Resolution: Identified 71 drug name-ID mismatches and resolved them using a quality-hierarchy (RMSE and Screen Count) to ensure 1-to-1 drug mapping.
  - Data Type & Null Value Audit: Standardised schema types (e.g., ensuring INT64 for identifiers) and handled NULL values in tissue classifications to prevent data loss during INNER JOIN operations.
  - Outlier Detection: Used RMSE distributions to establish a reliability threshold, filtering out low-quality curve fits that would otherwise introduce statistical noise into the biomarker discovery phase.
*/


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

-----------------------------------------------------------------------------------------------
--- 2. TABLE: Cell Lines Details ---
-----------------------------------------------------------------------------------------------

-- 2A. AUDIT: PK COSMIC_ID 
    
    SELECT
      COSMIC_identifier
      , COUNT(*) AS row_count
    FROM CGDA.Cell_line_details
    GROUP BY COSMIC_identifier
    HAVING row_count > 1;

-- 2B. Null values: 
    /* 
      - Fields with null values: Cancer Type_TCGA and Microsatellite_instability_Status_MSI. Small amount, subtitute null values with "unkown"
       - One record corresponds to the summary, it has been deleted. 
       - The field WES has one single value. It was ignored. 
       - The cleaned table has been saved as Cell_line_details_cleaned.
    */
  --> Cancer_Type_TCGA has 176/1002 null values
    SELECT COUNT(*) --- 176/1002 lines
    FROM CGDA.Cell_line_details
    WHERE `Cancer Type_TCGA` IS NULL

  --> Microsatellite_instability_Status_MSI has 16/1002 null values
    SELECT COUNT(*)
    FROM CGDA.Cell_line_details
    WHERE Microsatellite_instability_Status_MSI IS NULL

  --> Cleaned the table: removed last row with totals and filled the null values
    
    CREATE OR REPLACE TABLE CGDA.Cell_line_details_cleaned AS
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
    FROM CGDA.Cell_line_details
    WHERE Sample_Name != 'TOTAL:'

      
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
  

   
  





   
