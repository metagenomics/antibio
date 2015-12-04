#!/usr/bin/env python

"""
Usage: create_overview.py -u <HMM-Hits.unique> -faa <faa_folder> -o <output_folder>  [--search=<search_config.yaml>] -c <coverage_files>...

-h --help     Please enter a HMM.unique file, faa folder, output folder and as many coverage files as you want to.

"""
from sys import argv
from docopt import docopt
import functools
import csv
from Bio import SeqIO
import os
import shutil
import util
import yaml

def writeHeader(coverages, file, insertGroup):
    header = [util.GENE_ID,
              util.HMM, util.SCORE_HMM,
              util.EVAL_HMM, util.BEST_BLASTP_HIT,
              util.EVALUE_BEST_BLASTP, util.IDENTITY,
              util.SUBJECT_ACCESSION, util.SUBJECT_TITLES,
              util.SUBJECT_TAXIDS, util.SUBJECT_IDS,
              util.LINKS, util.GENE_SEQUENCE]
    if insertGroup:
        header.insert(2, util.GROUP)
    file.write(("\t".join(map(lambda cov:os.path.basename(cov),coverages) + header)) + '\n')


def move_txt_faa_files(output, file_txt, file_faa):
    if os.path.exists(file_txt):
        shutil.move(file_txt, output)
    if os.path.exists(file_faa):
        shutil.move(file_faa, output)

def move_html_files(output, file_html):
    if os.path.exists(file_html):
        shutil.move(file_html, output)

def load_search_config(file):
    return yaml.load(file)

def determine_config_values(config, hmm):
    """
    Returns group of the HMM protein.
    :param config: column patterns
    :param hmm: HMM
    :return: tuple of hmm and key
    """
    for group in config:
        for key in group:
            if hmm in group[key]:
                return (hmm, key)
    return (hmm, "N/A")

def get_contig_txt_information(contig):
    """
    Extracts contig information.
    :param contig: contig file
    :return: various information
    """
    BLASTP = util.NOT_AVAILABLE
    EVALUE = util.NOT_AVAILABLE
    IDENTITY = util.NOT_AVAILABLE
    SUBACCES = util.NOT_AVAILABLE
    SUBTIT = util.NOT_AVAILABLE
    SUBTAXID = util.NOT_AVAILABLE
    SUBID = util.NOT_AVAILABLE
    if os.path.isfile(contig):
        with open(contig, 'rb') as f:
            reader = csv.reader(f, delimiter='\t')
            for row in reader:
                BLASTP = row[1]
                EVALUE = row[10]
                IDENTITY = row[2]
                SUBACCES = row[12]
                SUBTIT = row[13]
                SUBTAXID = row[14]
                SUBID = row[15]
                break;
    return [BLASTP, EVALUE, IDENTITY, SUBACCES, SUBTIT, SUBTAXID, SUBID]


def get_coverage_information(coverage_path, id):
    """
    Extracts coverage information
    :param coverage_path:
    :param id: id of the contig
    :return: coverage value
    """
    with open(coverage_path, 'r') as coverage_file:
        cov = 0
        reader = csv.DictReader(coverage_file, delimiter='\t')
        for row in reader:
            contig = row[util.CONTIG_NAME] + "_"
            if (id.startswith(contig)):
                cov = row[util.AVG_COVERAGE]
        return cov


def get_sequence(contig_faa):
    """
    get sequence from a faa file with one entry
    :param contig_faa: faa sequence
    :return: faa sequence
    """
    seq = util.NOT_AVAILABLE
    if os.path.isfile(contig_faa) and not os.stat(contig_faa).st_size == 0:
        record = SeqIO.read(open(contig_faa), "fasta")
        seq = record.seq
    return seq

def main():
    args = docopt(__doc__, argv[1:])
    unique_file_path = args["<HMM-Hits.unique>"]
    faa_folder = args['<faa_folder>']
    output = args['<output_folder>']
    coverage_files = args['<coverage_files>']
    search_config =  args['--search']

    config = []
    if search_config:
        with open(search_config, "r") as config_file:
            config = load_search_config(config_file)
    faa_txt_folder = os.path.join(output, util.FAA_TXT_OUTPUT_FOLDER)
    html_folder = os.path.join(output, util.HTML_OUTPUT_FOLDER)

    if not os.path.exists(faa_txt_folder):
        os.makedirs(faa_txt_folder)
    if not os.path.exists(output):
        os.makedirs(html_folder)

    with open(unique_file_path, 'r') as unique, open(os.path.join(output, util.OVERVIEW_TXT), 'w') as output_file:
        writeHeader(coverage_files, output_file, bool(search_config))
        reader = unique.readlines()
        for line in reader:
            row = line.split()
            LINK = util.NO_LINK
            ID = row[3]
            HMM = row[0]
            SCORE = row[7]
            EVALHMM = row[6]
            txt_path = os.path.join(faa_folder, ID + ".txt")
            faa_path = os.path.join(faa_folder, ID + ".faa")

            coverages = map(functools.partial(get_coverage_information, id=ID), coverage_files)
            contig_txt_info = get_contig_txt_information(txt_path)

 	    SEQ = get_sequence(faa_path)

            BASE_COLUMNS = []
            if search_config:
                additional_column = determine_config_values(config, HMM)
                BASE_COLUMNS = [ID, HMM, additional_column[1], SCORE, EVALHMM]
            else:
                BASE_COLUMNS = [ID, HMM, SCORE, EVALHMM]

            coverages.extend(BASE_COLUMNS + contig_txt_info + [LINK, SEQ])
            output_file.write(('\t'.join(str(x) for x in coverages)) + '\n')

            move_html_files(html_folder, os.path.join(faa_txt_folder, ID + ".html"))
            move_txt_faa_files(faa_txt_folder, txt_path, faa_path)


if __name__ == '__main__':
    main()
