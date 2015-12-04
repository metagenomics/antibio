#!/usr/bin/env python

"""
Usage: fa_sizes.py --fa <fasta_file> --out <out_file>
"""
from sys import argv
from docopt import docopt
from Bio import SeqIO
import csv

CONTIG_CHUNK = 50
FASTA_HEADER_KEY = "header"
SIZE_HEADER_KEY = "size"

def write_sequences(fasta_file, out_file):
    records = SeqIO.parse(open(fasta_file), "fasta")
    with open(out_file, 'w') as out_file:
        out_writer = csv.DictWriter(out_file, delimiter='\t', extrasaction='ignore',
                                      fieldnames=[FASTA_HEADER_KEY, SIZE_HEADER_KEY])
        row = {FASTA_HEADER_KEY : "", SIZE_HEADER_KEY : "" }
        for record in records:
            row[FASTA_HEADER_KEY] = record.id
            row[SIZE_HEADER_KEY] = len(record.seq)
            out_writer.writerow(row)

def main():
    args = docopt(__doc__, argv[1:])
    fasta_file = args["<fasta_file>"]
    out_file = args["<out_file>"]
    write_sequences(fasta_file, out_file)


if __name__ == '__main__':
    main()
