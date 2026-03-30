fct_drug_sensitivity

COSMIC_ID: Unique identifier for the cell line from the COSMIC database.
SAMPLE_NAME: Unique identifier for the cell line sample.
TCGA_LABEL: Description of the cancer type according to The Cancer Genome Atlas.
CANCER_TYPE_DESCRIPTION: Primary tissue type classification.
CANCER_TYPE_DESCRIPTION_1: Secondary tissue type classification.
PRIMARY_SITE: Cancer type according to TCGA classification.

HISTOLOGY_TYPE: MISSING

CAN: Copy Number Alterations, data on gene copy number changes in the cell line.
GENE_EXPRESSION: Information on gene expression levels in the cell line.
METHYLATION: Data on DNA methylation patterns in the cell line.
MSI: Microsatellite instability Status indicates the cell line's MSI status.
GROWTH_PROPERTIES: Characteristics of how the cell line grows in culture.
DRUG_ID: Unique identifier for the drug used in the experiment.
DRUG_NAME: Name of the drug used in the experiment.
DRUG_TARGET: The molecular target(s) of the drug. 
DRUG_TARGET_PATHWAY: The biological pathway(s) targeted by the drug.

LN_IC50_CAPPED: MISSING

Z_SCORE: Standardised score of the drug response, allowing comparison across different drugs and cell lines.

SENSITIVITY_CALL: MISSING 

AUC: Area Under the Curve, a measure of drug effectiveness.
RMSE: Root Mean Square Error, indicating the fit quality of the dose-response curve.
SCREEN_MEDIUM: The growth medium used for culturing the cell line.
MIN_CONC: Minimum concentration of the drug used in the experiment.
MAX_CONC: Maximum concentration of the drug used in the experiment.




About Dataset
The Genomics of Drug Sensitivity in Cancer (GDSC) dataset is a valuable resource for therapeutic biomarker discovery in cancer research. This dataset combines drug response data with genomic profiles of cancer cell lines, allowing researchers to investigate the relationship between genetic features and drug sensitivity.

Task:
The primary task associated with this dataset is to predict drug sensitivity (measured as IC50 values) based on genomic features of cancer cell lines. This can involve regression tasks to predict exact IC50 values or classification tasks to categorize cell lines as sensitive or resistant to specific drugs. The dataset also allows for the identification of genomic markers that correlate with drug response.


GDSC2-dataset.csv: Contains drug sensitivity data, including IC50 values, for various drugs tested against cancer cell lines.(Original source file)
Cell_Lines_Details.xlsx: Provides detailed information about the cancer cell lines, including genomic features such as mutations, copy number alterations, and gene expression. (Original source file)
Compounds-annotation.csv: Offers information about the drugs used in the screening, including their targets and pathways. (Original source file)
GDSC_DATASET.csv: This is the main dataset file for analysis. It's a merged file combining key information from the above three files, created to facilitate easier analysis. This consolidated dataset includes all necessary features for drug sensitivity prediction and is recommended for use in your analysis.
Detailed Column Descriptions:

































