#!/usr/bin/env python3
"""
Power BI Data Pack Generator: E-Commerce Product Funnel & Cohort Retention
Exports clean analytics tables into a structured Excel workbook for Power BI Desktop.
"""

import os
import pandas as pd

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'data')
OUT_DIR = os.path.join(BASE_DIR, 'powerbi')

def main():
    print("Preparing Power BI Data Pack for E-Commerce Funnel & Cohort Retention...")
    
    df_funnel = pd.read_csv(os.path.join(DATA_DIR, 'funnel_summary.csv'))
    df_matrix = pd.read_csv(os.path.join(DATA_DIR, 'cohort_retention_matrix.csv'))
    df_counts = pd.read_csv(os.path.join(DATA_DIR, 'cohort_counts.csv'))
    df_cust = pd.read_csv(os.path.join(DATA_DIR, 'customer_summary.csv'))
    
    excel_path = os.path.join(OUT_DIR, 'powerbi_funnel_cohort_dataset.xlsx')
    with pd.ExcelWriter(excel_path, engine='openpyxl') as writer:
        df_funnel.to_excel(writer, sheet_name='funnel_summary', index=False)
        df_matrix.to_excel(writer, sheet_name='cohort_matrix', index=False)
        df_counts.to_excel(writer, sheet_name='cohort_counts', index=False)
        df_cust.head(3000).to_excel(writer, sheet_name='customer_summary', index=False)
        
    print(f"Generated Power BI Excel Workbook: {excel_path}")
    print("All retention and funnel tables staged for Power BI Desktop.")

if __name__ == '__main__':
    main()
