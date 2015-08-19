#!/usr/bin/env nextflow

params.str = "database"
process hmmFolderScan {

    output:
    file 'chunk_*' into letters mode flatten

    """
    #!/bin/sh

    # Script & Database paths
    HMMSEARCH=${params.HMM.SEARCH}
    HMMSCAN=${params.HMM.SCAN}
    HMMPRESS=${params.HMM.PRESS}
    CREATEFOLDER=${params.CREATEFOLDER}
    DATABASE=${params.DATABASE}
    CPU=${params.HMM.CPU}
    EVALUE=${params.HMM.EVALUE}
    IN=${params.HMM.INPUT}
    OUT=${params.HMM.OUTPUT}

    # All HMM files inside the input folder are merged to one big HMM file inside the output folder.
    cat $IN/*.hmm > $OUT/all.hmm

    # New HMM Databse needs to be indexed and precomputed for HMMScan to work.
    $HMMPRESS $OUT/all.hmm

    # Pipeline Folders are created with the help of a subscript.
    sh $CREATEFOLDER $OUT

    # If EValue is given, it is used in qsub call.
    if [ "$EVALUE" != "" ]; then
        EVALUE="-E $EVALUE"
    fi;

    #HMMScan qsub grid call.
    qsub -b y -pe multislot $CPU -N "HMMScan" -l vf=4G -l arch=lx24-amd64 -e $OUT/error/ -o $OUT/out/ -cwd $HMMSCAN $EVALUE --domtblout $OUT/all.domtblout --cpu $CPU -o $OUT/all.out $OUT/all.hmm $DATABASE
    """
}