/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: Table cleaning
PURPOSE: Cleaning tables: COSMIC_tissue_classification, Cell_line_details, GDSC2, TGCA_tissue_classification and screened_compounds
DATE: March 2026
*/


-----------------------------------------------------------------------------------------------
--- 1. TABLE: COSMIC_tissue_classification ---
-----------------------------------------------------------------------------------------------

--1A. Primary Key (PK): COSMIC_ID
  
    SELECT
      COSMIC_ID
      ,COUNT(*) AS row_count
    FROM COSMIC_tissue_classification
    GROUP BY COSMIC_ID
    HAVING row_count > 1;

-----------------------------------------------------------------------------------------------
--- 2. TABLE: Cell Lines Details ---
-----------------------------------------------------------------------------------------------

-- 2A. PK: COSMIC_ID 
    
    SELECT
      COSMIC_identifier
      , COUNT(*) AS row_count
    FROM Cell_line_details
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
    FROM Cell_line_details
    WHERE `Cancer Type_TCGA` IS NULL

  --> Microsatellite_instability_Status_MSI has 16/1002 null values
    SELECT COUNT(*)
    FROM Cell_line_details
    WHERE Microsatellite_instability_Status_MSI IS NULL

  --> Cleaned the table: removed last row with totals and filled the null values
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
      , CASE WHEN `Cancer Type_TCGA` IS NULL THEN "Unkown" 
          ELSE `Cancer Type_TCGA`END AS Cancer_Type_TCGA
      , CASE WHEN Microsatellite_instability_Status_MSI IS NULL THEN "Unkown"
          ELSE Microsatellite_instability_Status_MSI END AS MSI
    FROM Cell_line_details
    WHERE Sample_Name != 'TOTAL:'

      
-----------------------------------------------------------------------------------------------
--- 3. TABLE: GDSC2 ---
-----------------------------------------------------------------------------------------------

-- 2A. PK: COSMIC_ID and DRUG_ID
  
    SELECT
      COSMIC_ID
      , DRUG_ID
      , COUNT(*) AS row_count
    FROM GDSC2
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
    FROM GDSC2
    WHERE TCGA_DESC IS NULL 

  ---> PUTATIVE_TARGET has 27155/ 242036 null values, substitute them with 'unkown'.
    SELECT COUNT(*)
    FROM GDSC2
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
    SELECT 
      NLME_CURVE_ID 
      , COSMIC_ID
      , CELL_LINE_NAME
      , SANGER_MODEL_ID
      -- substituted null values by "uknown"
      , CASE WHEN TCGA_DESC IS NULL THEN "unknown" 
        ELSE TCGA_DESC END AS TCGA_DESC
      , DRUG_ID
      , DRUG_NAME
       -- substituted null values by "uknown"
      , CASE WHEN PUTATIVE_TARGET IS NULL THEN "unknown" 
        ELSE PUTATIVE_TARGET END AS PUTATIVE_TARGET
      , PATHWAY_NAME
      , COMPANY_ID
      , MIN_CONC
      , MAX_CONC
      -- Capped IC50: if IC_50 > the LOG(MAX_CONC), pull it down to the MAX_CONC
      ,CASE 
          WHEN LN_IC50 > LOG(MAX_CONC) THEN LOG(MAX_CONC) 
          ELSE LN_IC50 
      END AS LN_IC50_CAPPED
      , LN_IC50
      , AUC
      , RMSE
      , Z_SCORE
       -- added a new metric "sensitivity call" detialing the drug response
      , CASE 
          WHEN Z_SCORE < -1.5 AND LN_IC50 <= LOG(MAX_CONC) THEN 'SENSITIVE'
          WHEN Z_SCORE > 0.5 OR LN_IC50 > LOG(MAX_CONC) THEN 'RESISTANT'
          ELSE 'INTERMEDIATE'
      END AS SENSITIVITY_CALL
    FROM GDSC2
   
  





   
