# Cancer-Genomics-Drug-Analysis
Predicting drug sensitivity (IC50) in cancer cell lines using genomic features. Analysis of the GDSC dataset.

## Dataset Overview
The Genomics of Drug Sensitivity in Cancer (GDSC) dataset is a foundational resource for cancer research, combining drug response data with genomic profiles of 1,000+ cancer cell lines.

## Objective:
The objective is to analyze and predict Drug Sensitivity, primarily measured as $LN\_IC50$ (Natural log of the half-maximal inhibitory concentration).Low $LN\_IC50$: High drug sensitivity (the drug is effective).High $LN\_IC50$: Drug resistance (the drug is less effective).

## Data Architecture
I used four primary files provided by the Sanger Institute and Massachusetts General Hospital:

| File | Size | Description | Key Features |
| :--- | :--- | :--- | :--- |
| **GDSC2-dataset.csv** | 36.32 MB | Raw drug sensitivity results | LN_IC50, AUC, RMSE, Z-Score |
| **Cell_Lines_Details.xlsx**| 117.32 KB| Genomic profiles of cell lines | WES, CNA, Gene Expression |

> **Link to Original Source:** [GDSC Database](https://www.cancerrxgene.org/downloads/bulk_download)

## Methodology & Collection
Data was collected through large-scale screening using the CellTiter-Glo assay after 72 hours of treatment. This project investigates how genetic variations (mutations, copy numbers, and expression) correlate with these drug responses to identify potential therapeutic biomarkers.
