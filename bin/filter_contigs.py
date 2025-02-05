#!/usr/bin/env python3
import argparse
import pandas as pd
import pysam

def get_args():

    parser = argparse.ArgumentParser(
            prog="filter_contigs",
        )
    parser.add_argument(
        dest = "fasta"
    )
    parser.add_argument(
        "-t",
        "--taxonomy",
        dest="taxonomy",
        help="path to the mmseqs2taxonomy annotations",

    )
    parser.add_argument(
            "-d",
            "--depth",
            dest="depth",
            help="path to the depth file",

    )
    parser.add_argument(
        "-b",
        "--basename",
        dest="basename",
        help="basename",
    )
    parser.add_argument(
            "-m",
            "--minlen",
            dest="minlen",
            type=int,
            default=250,
            help="Minimum contig length"
    )

    return parser.parse_args()


def filter_fasta(taxonomy, depth, fasta, minlen, basename):
    contigs_pass = set()
    with pysam.FastxFile(fasta) as fin, open(f"{basename}.length_filtered.fa", mode='w') as fout:
        for entry in fin:
            if len(entry.sequence) > minlen:
                contigs_pass.add(entry.name)
                fout.write(str(entry) + '\n')
            else:
                print(f"{entry.name} is less than {minlen} bp")

    d = pd.read_table(depth)
    t = pd.read_table(taxonomy)

    d = d.query('contigname in @contigs_pass')
    t = t.query('contigs in @contigs_pass')
    print(d)

    d.to_csv(f"{basename}.depth_filtered.tsv", index=False, sep='\t')
    t.to_csv(f"{basename}.taxonomy_filtered.tsv", index=False, sep='\t')



if __name__ == "__main__":
    args = get_args()

    filter_fasta(
        args.taxonomy,
        args.depth,
        args.fasta,
        args.minlen,
        args.basename
    )

