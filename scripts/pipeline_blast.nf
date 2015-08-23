#!/usr/bin/env nextflow

params.in = "$baseDir/all.uniq"
params.db = "$baseDir/db.faa"

uniq_file = file(params.in)
uniq_lines = uniq_file.readLines()
db_file = file(params.db)

process getFastaHeader {

    input:
    val contig from uniq_lines
    file db_file
    
    output:
    file 'uniq_header'
    
    """
    #!/bin/sh
    grep "$contig " $db_file > uniq_header 
    """  

}

process getContigSeq {

    input:
    file db_file
    file uniq_header
    
    output:
    file 'uniq_seq'
    
    shell:
    '''
    #!/bin/sh
    buffer=$(cat uniq_header | cut -c 2-)
    contig=$(echo $buffer | cut -d" " -f1)
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' "!{db_file}" > !{baseDir}/$contig.faa
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' "!{db_file}" > uniq_seq
    '''

}

process blastSeq {

    input:
    file uniq_seq
    
    output:
    stdout result
    
    shell:
    '''
    #!/bin/sh
    contig=$(grep ">" !{uniq_seq} | cut -d" " -f1 | cut -c 2-)
    echo !{params.BLAST.P} -db !{params.DATABASE.NCBI} -outfmt \\"6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore sallacc salltitles staxids sallseqid\\" -query "!{uniq_seq}" -out "!{baseDir}/$contig.txt" -num_threads !{params.BLAST.CPU}
    echo !{params.BLAST.P} -db !{params.DATABASE.NCBI} -query "!{uniq_seq}" -html -out "!{baseDir}/$contig.html" -num_threads !{params.BLAST.CPU} 
    '''

}

/*
 * get all stdout printed
 */
result.subscribe { println it }
