/* PROJECT: Cancer Genomics Drug Analysis (GDSC)
SCRIPT: 01_validation_scripts.sql
PURPOSE: Identifying structural inconsistencies, PK violations, and null distributions.
DATE: March 2026
*/

---------------------------------------------------------------------------------
-- 1. PRIMARY KEY (PK) VALIDATION
-- Ensuring uniqueness of identifiers before joining tables.
---------------------------------------------------------------------------------

-- AUDIT: COSMIC_tissue_classification PK
SELECT COSMIC_ID, COUNT(*) AS row_count
FROM `PROJECT_ID.CGDA.COSMIC_tissue_classification`
GROUP BY 1 HAVING row_count > 1;

-- AUDIT: Cell_line_details PK
SELECT COSMIC_identifier, COUNT(*) AS row_count
FROM `PROJECT_ID.CGDA.Cell_line_details`
GROUP BY 1 HAVING row_count > 1;

-- AUDIT: GDSC2 Composite PK (Cell + Drug)
SELECT COSMIC_ID, DRUG_ID, COUNT(*) AS row_count
FROM `PROJECT_ID.CGDA.GDSC2`
GROUP BY 1, 2 HAVING row_count > 1;

-- AUDIT: screened_compounds PK
SELECT DRUG_ID, COUNT(*) AS row_count
FROM `PROJECT_ID.CGDA.screened_compounds`
GROUP BY 1 HAVING row_count > 1;

---------------------------------------------------------------------------------
-- 2. NULL & DATA QUALITY AUDIT
-- Quantifying missingness in critical biomarker columns.
---------------------------------------------------------------------------------

-- AUDIT: Nulls in Cell Line Metadata
SELECT 
    COUNTIF(`Cancer Type_TCGA` IS NULL) AS null_tcga,
    COUNTIF(Microsatellite_instability_Status_MSI IS NULL) AS null_msi
FROM `PROJECT_ID.CGDA.Cell_line_details`;

-- AUDIT: Nulls in Drug Response (GDSC2)
SELECT 
    COUNTIF(TCGA_DESC IS NULL) AS null_tcga_desc,
    COUNTIF(PUTATIVE_TARGET IS NULL) AS null_target
FROM `PROJECT_ID.CGDA.GDSC2`;

-- AUDIT: Blank strings in Drug Targets
SELECT COUNT(*) AS blank_targets
FROM `PROJECT_ID.CGDA.screened_compounds`
WHERE TRIM(`TARGET`) = "";
