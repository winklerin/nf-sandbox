#!/usr/bin/env python3
import time
import argparse
import pandas as pd

# Adapted from https://github.com/RasmussenLab/taxconverter

LINEAGE_COL = 'lineage'
SEQ_COL = 'sequences'

def all_to_taxvamb(df: pd.DataFrame):
    df[LINEAGE_COL] = df[LINEAGE_COL].fillna('unknown')
    df = df[[SEQ_COL, LINEAGE_COL]]
    df.columns = ['contigs', 'predictions']
    return df

def mmseqs_data(filepath: str):
    begintime = time.time()
    df_mmseqs = pd.read_csv(filepath, header=None, delimiter='\t')
    df_mmseqs[SEQ_COL] = df_mmseqs[0]
    df_mmseqs[LINEAGE_COL] = df_mmseqs[8]
    elapsed = round(time.time() - begintime, 2)
    print(f"Converted MMseqs2 format in {elapsed} seconds")
    return df_mmseqs

if __name__ == "__main__":
    doc = f"""
    Convert outputs of MMSeqs to the unified format for TaxVAMB tool."""
    parser = argparse.ArgumentParser(
        prog="taxconverter",
        description=doc,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        add_help=False,
    )
    parser.add_argument(
        "-h", "--help", action="help", help="show this help message and exit"
    )
    parser.add_argument(
        "-i",
        "--input",
        dest="input",
        help="path to the mmseqs2taxonomy annotations",

    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output",
        default="taxvamb.tsv",
        help="path to save the converted annotations",
    )
    args = parser.parse_args()

    mmseqs_df = mmseqs_data(args.input)
    taxvamb_df = all_to_taxvamb(mmseqs_df)
    taxvamb_df.to_csv(args.output, sep='\t', index=False)
