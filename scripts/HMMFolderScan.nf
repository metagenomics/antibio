#!/usr/bin/env nextflow

process hmmFolderScan {

    cpus ${params.HMM.CPU}

    memory '4 GB'

    """
    #!/bin/sh
    # All HMM files inside the input folder are merged to one big HMM file inside the output folder.
    cat ${params.HMM.INPUT}/*.hmm > ${params.HMM.OUTPUT}/all.hmm

    # New HMM Databse needs to be indexed and precomputed for HMMScan to work.
    ${params.HMM.PRESS} ${params.HMM.OUTPUT}/all.hmm

    # Pipeline Folders are created with the help of a subscript.
    sh ${params.CREATEFOLDER} ${params.HMM.OUTPUT}

    #HMMScan qsub grid call.
    ${params.HMM.SCAN} -E ${params.HMM.EVALUE} --domtblout ${params.HMM.OUTPUT}/all.domtblout --cpu ${params.HMM.CPU} -o ${params.HMM.OUTPUT}/all.out ${params.HMM.OUTPUT}/all.hmm ${params.DATABASE}
    """
}
