#!/usr/bin/env python

"""
Usage: gff2bed.py --gff <gff_file> --bed <bed_file>
"""
from sys import argv
from docopt import docopt
import pybedtools
import os
from pybedtools.featurefuncs import gff2bed

def transform_bed(bed_file, output_bed_file):
    with open(bed_file, 'r') as bed_file, open(output_bed_file, 'w') as output_bed_file:
        for line in bed_file:
            fields = line.rstrip('\n').split("\t")
            fields[4] = str(int(float(fields[4])))
            start = fields[1]
            stop = fields[2]
            thickStart = start
            thickStop = start
            rgb = "255,0,0"
            blockCount = "1"
            blockSizes = str(int(stop) - int(start))
            blockStarts = str(0)
            additional = [thickStart, thickStop, rgb, blockCount, blockSizes, blockStarts]
            fields.extend(additional)
            output_bed_file.write("\t".join(fields) + "\n")

def gff_to_bed(gff_file, bed_file):
    pybedtools.example_bedtool(gff_file).each(gff2bed).saveas(bed_file)

def main():
    args = docopt(__doc__, argv[1:])
    gff_file = args["<gff_file>"]
    bed_file = args["<bed_file>"]
    bed_file_tmp = bed_file + ".tmp"
    gff_to_bed(os.path.realpath(gff_file), bed_file_tmp)
    transform_bed(bed_file_tmp, bed_file)

if __name__ == '__main__':
    main()
