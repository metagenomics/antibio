#!/usr/bin/env python

"""
Usage: view_index.py --faa <faa_file> --contigs <assembly_file> --gff <gff_file> --gffdir <gff_dir> --out <index_out>
"""
from sys import argv
from docopt import docopt
from Bio import SeqIO
import os
from BCBio import GFF
import csv

CONTIG_CHUNK = 50
FAA_INDEX_KEY = "faaIndex"
FEATURE_START_KEY = "faaStart"
FEATURE_STOP_KEY = "faaStop"
FAA_HEADER_KEY = "faaHeader"
FIX_HEADER_KEY = "fix_name"
ASSEMBLY_CONTIG_KEY = "contig_id"
GFF_CONTIG_KEY = "gff_contig_id"
CONTIG_INDEX_KEY = "contig_index"
CONTIG_BIT_KEY = "bitNum"

def get_next_contig_id(gff_iter, feature_iter):
    if(feature_iter.next() == None):
        gff_iter.next()

def write_contig_gff(path, contig):
    with open(path, "w") as out_handle:
        GFF.write([contig], out_handle)

def main():
    args = docopt(__doc__, argv[1:])
    faa_file = args["<faa_file>"]
    gff_file = args["<gff_file>"]
    assembly_file = args["<assembly_file>"]
    gff_out = args["<gff_dir>"]
    index_file_path = args["<index_out>"]

    faa_records = SeqIO.parse(open(faa_file), "fasta")
    assembly_records = SeqIO.parse(open(assembly_file), "fasta")
    with open(index_file_path, 'w') as index_file:
        index_writer = csv.DictWriter(index_file, delimiter='\t', extrasaction='ignore',
                                      fieldnames=[CONTIG_BIT_KEY, CONTIG_INDEX_KEY, ASSEMBLY_CONTIG_KEY, GFF_CONTIG_KEY, FAA_INDEX_KEY,
                                                  FAA_HEADER_KEY, FIX_HEADER_KEY, FEATURE_START_KEY, FEATURE_STOP_KEY])
        index_writer.writeheader()
        faa_index = 0
        contig_index = 0
        assembly_record = assembly_records.next()
        with open(gff_file) as gff_handle:
            gff_iter = GFF.parse(gff_handle, target_lines=1000)
            row = {}
            contig = gff_iter.next()
            feature_iter = iter(list(contig.features))
            write_contig_gff(os.path.join(gff_out, contig.id + ".gff"), contig)
            for record in faa_records:
                try:
                    feature = feature_iter.next()
                except StopIteration:
                    try:
                        write_contig_gff(os.path.join(gff_out, contig.id + ".gff"), contig)
                        contig = gff_iter.next()
                        assembly_record = assembly_records.next()
                        contig_index += 1
                    except StopIteration:
                        break
                    feature_iter = iter(list(contig.features))
                    feature = feature_iter.next()
                row[FAA_INDEX_KEY] = faa_index
                row[FEATURE_START_KEY] = feature.location._start.position
                row[FEATURE_STOP_KEY] = feature.location._end.position
                row[FAA_HEADER_KEY] = record.description
                row[FIX_HEADER_KEY] = record.id
                row[ASSEMBLY_CONTIG_KEY] = assembly_record.description
                row[GFF_CONTIG_KEY] = contig.id
                row[CONTIG_INDEX_KEY] = contig_index
                row[CONTIG_BIT_KEY] = row[FAA_INDEX_KEY]/CONTIG_CHUNK + 1
                faa_index += 1
                index_writer.writerow(row)

if __name__ == '__main__':
    main()
