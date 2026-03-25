/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: Table cleaning
PURPOSE: Cleaning tables: COSMIC_tissue_classification, Cell_line_details, GDSC2, TGCA_tissue_classification and screened_compounds
DATE: March 2026
*/


----------------------------------------------
--- 1. TABLE: COSMIC_tissue_classification ---
----------------------------------------------

--1A. PK: COSMIC_ID
  
    SELECT
      COSMIC_ID
      ,COUNT(*) AS row_count
    FROM COSMIC_tissue_classification
    GROUP BY COSMIC_ID
    HAVING row_count > 1;

-- 2B. No null values
    SELECT
    Line
    , COSMIC_ID
    , Site
    , Histology
    FROM COSMIC_tissue_classification
    WHERE 
      Line IS NULL  
      OR COSMIC_ID IS NULL 
      OR Site IS NULL
      OR Histology IS NULL;

   
