#!/usr/bin/env nextflow

params.in = "$baseDir/all.uniq"
params.db = "$baseDir/db.faa"

/*
 * Read input in as files and line by line
 */
uniq_file = file(params.in)
uniq_lines = uniq_file.readLines()
db_file = file(params.db)

process getFastaHeader {

    cpus 2
    memory '1 GB'

    input:
    val contig from uniq_lines
    file db_file
    
    output:
    file 'uniq_header'
   
/*
 * All lines in the $contig variable are contigs, to be searched in the $db_file.
 * grep finds these contigs and supplies there fasta header.
 */ 
    """
    #!/bin/sh
    grep "$contig " $db_file > uniq_header 
    """  

}

process getContigSeq {
    
    cpus 2
    memory '1 GB'
    
    input:
    file db_file
    file uniq_header
    
    output:
    file 'uniq_seq'
    file 'uniq_seqHtml'
    
/*
 * The fasta headers of the previous process is used, to find and extract the whole fasta sequence.
 * This is done three times. Once to save the sequence in an file for further use. The second and third time,
 * to pipe them into two channels to be used by the next processes. 
 */
    shell:
    '''
    #!/bin/sh
    buffer=$(cat uniq_header | cut -c 2-)
    contig=$(echo $buffer | cut -d" " -f1)
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' "!{db_file}" > !{baseDir}/$contig.faa
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' "!{db_file}" > uniq_seq
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' "!{db_file}" > uniq_seqHtml
    '''

}

process blastSeqTxt {
    
    cpus 4
    memory '4 GB'
    
    input:
    file uniq_seq
    
    script:
    order = "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sallacc salltitles staxids sallseqid"
/*
 * blast all fasta sequences against the ncbi database. A special output format is used, to make the data usable for the next pipeline.
 */ 
    shell:
    '''
    #!/bin/sh
    contig=$(grep ">" !{uniq_seq} | cut -d" " -f1 | cut -c 2-)
    !{params.BLAST.P} -db !{params.DATABASE.NCBI} -outfmt "!{order}" -query "!{uniq_seq}" -out "!{baseDir}/$contig.txt" -num_threads !{params.BLAST.CPU}
    '''

}

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
    contig=$(grep ">" !{uniq_seqHtml} | cut -d" " -f1 | cut -c 2-)
    !{params.BLAST.P} -db !{params.DATABASE.NCBI} -query "!{uniq_seqHtml}" -html -out "!{baseDir}/$contig.html" -num_threads !{params.BLAST.CPU} 
    '''

}
