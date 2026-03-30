/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: 03_fct_drug_sensitivity_merge.sql
PURPOSE: Final integration of cell line, drug metadata, and response metrics.
         Creates the 'Golden Record' Fact Table for downstream BI and modelling.
DATE: March 2026

DATA ARCHITECTURE DECISIONS:
- Tissue Labelling: Retained 'Cancer_Type_TCGA' over 'TCGA_DESC' for superior data completeness.
- Drug Mapping: Prioritised 'PUTATIVE_TARGET' and 'PATHWAY_NAME' as the primary biological descriptors.
- Dimensionality: Denormalised tissue site and histology for high-performance dashboard filtering.
*/

CREATE OR REPLACE TABLE `PROJECT_ID.CGDA.fct_drug_sensitivity` AS

SELECT  
    -- A. Cell Line Identity 
    GDSC2.COSMIC_ID
    , cell.Sample_Name AS SAMPLE_NAME
    , cell.Cancer_Type_TCGA AS TCGA_LABEL
    , COALESCE(ttis.TCGA_name, 'Unknown') AS CANCER_TYPE_DESCRIPTION
    , ctis.Site AS PRIMARY_SITE
    , ctis.Histology AS HISTOLOGY_TYPE
    , cell.CAN
    , cell.Gene_Expression AS GENE_EXPRESSION
    , cell.Methylation AS METHYLATION
    , cell.MSI
    , cell.Growth_Properties AS GROWTH_PROPERTIES
    
    -- B. Drug Identity 
    , GDSC2.DRUG_ID AS DRUG_ID
    , GDSC2.DRUG_NAME AS DRUG_NAME
    , CASE 
        WHEN TRIM(GDSC2.PUTATIVE_TARGET) = "" OR GDSC2.PUTATIVE_TARGET IS NULL 
        THEN 'Unknown' ELSE GDSC2.PUTATIVE_TARGET 
      END AS DRUG_TARGET
    , GDSC2.PATHWAY_NAME AS DRUG_TARGET_PATHWAY
    
    -- C. Response Metrics 
    , GDSC2.LN_IC50_CAPPED
    , GDSC2.Z_SCORE
    , GDSC2.SENSITIVITY_CALL
    , GDSC2.AUC
    , GDSC2.RMSE
    
    -- D. Experimental Metadata
    , cell.Screen_Medium AS SCREEN_MEDIUM
    , GDSC2.MIN_CONC
    , GDSC2.MAX_CONC

FROM `CGDA.GDSC2_cleaned` AS GDSC2
INNER JOIN `CGDA.Cell_line_details_cleaned` AS cell
  ON COSMIC_ID = cell.COSMIC_identifier
LEFT JOIN `CGDA.COSMIC_tissue_classification` AS ctis
  ON GDSC2.COSMIC_ID = ctis.COSMIC_ID 
LEFT JOIN `CGDA.TGCA_tissue_classification_cleaned` AS ttis
  ON GDSC2.TCGA_DESC = ttis.TCGA_DESC;



------------------------------------------------------------------------------------
-- POST-MERGE VALIDATION (Unit Tests)
-- These queries verify that the join logic did not result in data loss or inflation.
------------------------------------------------------------------------------------

/* -- TEST 1: Row Count Preservation (Expected: 242,036)
SELECT count(*) FROM `PROJECT_ID.CGDA.fct_drug_sensitivity`;

-- TEST 2: Null Audit across critical dimensions
SELECT * FROM `PROJECT_ID.CGDA.fct_drug_sensitivity`
WHERE COSMIC_ID IS NULL OR DRUG_ID IS NULL OR TCGA_LABEL IS NULL;

-- TEST 3: Referential Integrity Audit
-- (Checks for any responses that failed to map to cell line metadata)
SELECT GDSC2.COSMIC_ID
FROM `PROJECT_ID.CGDA.GDSC2_cleaned` AS GDSC2
LEFT JOIN `PROJECT_ID.CGDA.Cell_line_details_cleaned` AS cell
  ON GDSC2.COSMIC_ID = cell.COSMIC_identifier
WHERE cell.COSMIC_identifier IS NULL;
*/
