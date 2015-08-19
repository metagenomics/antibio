#!/usr/bin/env nextflow

params.str = "database"
process hmmFolderScan {

    """
    #!/bin/sh
    # All HMM files inside the input folder are merged to one big HMM file inside the output folder.
    cat ${params.HMM.INPUT}/*.hmm > ${params.HMM.OUTPUT}/all.hmm

    # New HMM Databse needs to be indexed and precomputed for HMMScan to work.
    ${params.HMM.PRESS} ${params.HMM.OUTPUT}/all.hmm

    # Pipeline Folders are created with the help of a subscript.
    sh ${params.CREATEFOLDER} ${params.HMM.OUTPUT}

    # If EValue is given, it is used in qsub call.
    if [ "${params.HMM.EVALUE}" != "" ]; then
        EVALUE="-E ${params.HMM.EVALUE}"
    fi;

    #HMMScan qsub grid call.
    qsub -b y -pe multislot ${params.HMM.CPU} -N "HMMScan" -l vf=4G -l arch=lx24-amd64 -e ${params.HMM.OUTPUT}/error/ -o ${params.HMM.OUTPUT}/out/ -cwd ${params.HMM.SCAN} ${params.HMM.EVALUE} --domtblout ${params.HMM.OUTPUT}/all.domtblout --cpu ${params.HMM.CPU} -o ${params.HMM.OUTPUT}/all.out ${params.HMM.OUTPUT}/all.hmm ${params.DATABASE}
    """
}