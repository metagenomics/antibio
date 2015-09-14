#!/usr/bin/env nextflow

process hmmFolderScan {

    cpus "${params.HMM.CPU}"

    memory '4 GB'
    cache false

    input:
    file hmmInput from '${params.HMM.INPUT}'   

    output:
    file domtblout
    file allOut
    file outputFasta 

    """
    #!/bin/sh
    # All HMM files inside the input folder are merged to one big HMM file inside the output folder.
    cat ${params.HMM.INPUT}/*.hmm > allHmm

    # New HMM Databse needs to be indexed and precomputed for HMMScan to work.
    ${params.HMM.PRESS} allHmm

    # Pipeline Folders are created with the help of a subscript.
    sh ${params.CREATEFOLDER} ${params.HMM.OUTPUT}

    #HMMScan qsub grid call.
    ${params.HMM.SCAN} -E ${params.HMM.EVALUE} --domtblout domtblout --cpu ${params.HMM.CPU} -o allOut allHmm ${params.DATABASE.GENOME}
    touch outputFasta
    """
}

params.num = 1
num = params.num

process uniqer {
    
    cache false

    input:
    file domtblout
    file outputFasta
    params.num
      
    output:
    file outputFasta into fastaFiles

    """
    $baseDir/scripts/uniquer.sh $num domtblout outputFasta
    """    
}

uniq_lines = Channel.create()
uniq_overview = Channel.create()
fastaFiles.separate( fastaFiles, uniq_overview ) { a -> [a, a] }
fastaFiles.flatMap{ file -> file.readLines() }.into(uniq_lines)

/* end = Channel.create()
   fastaFiles.subscribe onComplete: { end.bind("start") }
   end.subscribe{print it} */

process getFastaHeader {

    cpus 2

    memory '1 GB'

    input:
    val contig from uniq_lines
    
    output:
    file 'uniq_header'

    """
    #!/bin/sh
    grep  `echo "$contig " | cut -d ' ' -f 4`  ${params.DATABASE.GENOME} > uniq_header
    """  

}

process getContigSeq {
    
    cpus 2
    memory '1 GB'
    
    input:
    params.DATABASE.GENOME
    file uniq_header
    
    output:
    file 'uniq_out'
    
/*
 * The fasta headers of the previous process is used, to find and extract the whole fasta sequence.
 * This is done three times. Once to save the sequence in an file for further use. The second and third time,
 * to pipe them into two channels to be used by the next processes. 
 */
    shell:
    '''
    #!/bin/sh
    buffer=`cat uniq_header | cut -c 2-`
    contig=`echo $buffer | cut -d" " -f1`
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' !{params.DATABASE.GENOME}  > !{baseDir}/$contig.faa
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' !{params.DATABASE.GENOME}  > uniq_out
    '''

}

uniq_seq = Channel.create()
uniq_seqHtml = Channel.create()
uniq_out.separate( uniq_seq, uniq_seqHtml ) { a -> [a, a] }

process blastSeqTxt {
    
    cpus 4
    memory '4 GB'
    
    input:
    file uniq_seq

    output:
    file blast_out
    
    script:
    order = "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sallacc salltitles staxids sallseqid"
/*
 * blast all fasta sequences against the ncbi database. A special output format is used, to make the data usable for the next pipeline.
 */ 
    shell:
    '''
    #!/bin/sh
    contig=`grep ">" !{uniq_seq} | cut -d" " -f1 | cut -c 2-`
    !{params.BLAST.P} -db !{params.DATABASE.NCBI} -outfmt '!{order}' -query "!{uniq_seq}" -out "!{baseDir}/$contig.txt" -num_threads !{params.BLAST.CPU}
    echo "$contig" > blast_out
    '''
}

blast_all = Channel.create()
blast_out
   .collectFile()
   .into(blast_all)

process blastSeqHtml {

    cpus 4
    memory '4 GB'

    input:
    file uniq_seqHtml

/*
 * blast all fasta sequences against the ncbi database. The output is html formated, to get it legible for people.
 */
    shell:
    '''
    #!/bin/sh
    contig=`grep ">" !{uniq_seqHtml} | cut -d" " -f1 | cut -c 2-`
    !{params.BLAST.P} -db !{params.DATABASE.NCBI} -query "!{uniq_seqHtml}" -html -out "!{baseDir}/$contig.html" -num_threads !{params.BLAST.CPU} 
    '''

}

PYTHON="$baseDir/vendor/python/bin/python"


coverages = Channel.create()
coverages.bind(params.cov.replaceAll(',',' '))

bam = Channel.from(params.bam)
sortedIndexedBam = bam.flatMap{ files  -> files.split(',')} 

process bamToCoverage {
   
   cpus 2

   memory '4 GB'

   input: 
   val bam from sortedIndexedBam

   output:
   file coverage into coverages
   
   when:
   bam != ''

   script:
   """
   #!/bin/sh
   $baseDir/scripts/bam_to_coverage.pl ${params.sortedIndexedBam} > coverage
   """
}

coverageFiles = Channel.create()
coverages.toList().into(coverageFiles)

process createOverview {
   
   cpus 2

   memory '4 GB'

   input:
   file blast_all
   file uniq_overview
   val coverageFiles

   output:
   val params.out + '/overview.txt' into over

   """
   #!/bin/sh
   $PYTHON $baseDir/scripts/create_overview.py -u ${uniq_overview}  -faa $baseDir -o ${params.out}  -c ${coverageFiles.join(' ')} 
   """
}

process linkSearch {
   
   cpus 2

   memory '4 GB'

   input: 
   val x from over
   params.out

   output:
   val params.out into inputF 

   """
   #!/bin/sh
   $PYTHON $baseDir/scripts/link_search.py -o ${x} -out ${params.out} 
   touch hier.txt
   """
}


process folderToPubmed {
   
   cpus 2

   memory '4 GB'

   input:
   val inp from inputF
   params.out

   output:
   val params.out + '/all.pubHits'  into pub
   val params.out + '/overview.txt' into over2

   """
   #!/bin/sh
   sh $baseDir/scripts/FolderToPubmed.sh ${inp} ${params.out}  $baseDir/scripts/UrltoPubmedID.sh
   """
}


process linkAssignment {
 
   cpus 2
 
   memory '6 GB'

   input:
   val x from over2
   val p from pub

   """
   #!/bin/sh
   $PYTHON $baseDir/scripts/link_assignment.py -o ${x} -pub ${p} 
   """
}
