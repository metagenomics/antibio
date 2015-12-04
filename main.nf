#!/usr/bin/env nextflow

params.vendor = "$baseDir/vendor"
params.search = ""
params.keywords = ""
params.help = ""
params.cov = ""
params.faa = ""

if( params.help ) { 
    usage = file("$baseDir/usage.txt")   
    print usage.text
    return 
}

hmmDir = file(params.input)
outputDir = file(params.output)
ncbiDB = file(params.ncbi)
genomeFaa = file(params.genome)

keywordsFile = ""
if(params.keywords){
	keywordsFile = file(params.keywords)
}

searchFile = ""
if(params.search){
	searchFile = file(params.search)
}

process bootstrap {

   executor 'local'

   input:
   params.vendor
   
   output:
   file allHmm

   shell:
   if(outputDir.exists()) 
      exit(0, "Directory ${outputDir} already exists. Please remove it or assign another output directory.")
   else
      outputDir.mkdir()
      """
      #!/bin/bash
      if [ ! -d !{params.vendor} ]
      then
          make -C !{baseDir} install 
      fi
      cat !{hmmDir}/*.hmm > allHmm
      ${params.hmm_press} allHmm
      """
}

fastaChunk = Channel.create()
list = Channel.fromPath(genomeFaa).splitFasta(by:6000,file:true).collectFile();
list.spread(allHmm).into(fastaChunk)

process hmmFolderScan {

    cpus "${params.hmm_cpu}"

    memory '8 GB'
    cache false

    maxForks 6000 

    input:
    val chunk from fastaChunk

    output:
    file domtblout

    script:
    fastaChunkFile = chunk[0]
    hmm = chunk[1] 
    """
    #!/bin/sh
    ${params.hmm_scan} -E ${params.hmm_evalue} --domtblout domtblout --cpu ${params.hmm_cpu} -o allOut ${hmm} ${fastaChunkFile}
    """
}
    
params.num = 1
num = params.num

process uniqer {
    
    cache false

    input:
    file domtblout
    params.num
      
    output:
    file outputFasta into fastaFiles

    """
    $baseDir/scripts/uniquer.sh $num domtblout outputFasta
    """    
}

uniq_lines = Channel.create()
uniq_overview = Channel.create()
fastaFiles.filter({it -> java.nio.file.Files.size(it)!=0}).tap(uniq_overview).flatMap{ file -> file.readLines() }.into(uniq_lines)

process getFasta {

    executor 'local'

    cpus 2

    memory '1 GB'

    input:
    val contigLine from uniq_lines
    
    output:
    file 'uniq_out'
    
    shell:
    '''
    #!/bin/sh
    contig=`echo "!{contigLine} " | cut -d ' ' -f 4`
    grep  "$contig " !{genomeFaa} > uniq_header
    buffer=`cat uniq_header | cut -c 2-`
    contig=`echo $buffer | cut -d" " -f1`
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' !{genomeFaa}  > !{baseDir}/$contig.faa
    awk -v p="$buffer" 'BEGIN{ ORS=""; RS=">"; FS="\\n" } $1 == p { print ">" $0 }' !{genomeFaa}  > uniq_out
    '''  

}

uniq_seq = Channel.create()
uniq_seqHtml = Channel.create()
uniq_out.separate( uniq_seq, uniq_seqHtml ) { a -> [a, a] }

process blastSeqTxt {
    
    cpus 4
    memory '8 GB'
    
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
    !{params.blastp} -db !{ncbiDB} -outfmt '!{order}' -query "!{uniq_seq}" -out "!{baseDir}/$contig.txt" -num_threads !{params.blast_cpu}
    echo "$contig" > blast_out
    '''
}

blast_all = Channel.create()
blast_out
   .collectFile()
   .into(blast_all)

process blastSeqHtml {

    cpus 4
    memory '8 GB'

    input:
    file uniq_seqHtml

/*
 * blast all fasta sequences against the ncbi database. The output is html formated, to get it legible for people.
 */
    shell:
    '''
    #!/bin/sh
    contig=`grep ">" !{uniq_seqHtml} | cut -d" " -f1 | cut -c 2-`
    !{params.blastp} -db !{ncbiDB} -query "!{uniq_seqHtml}" -html -out "!{outputDir}/$contig.html" -num_threads !{params.blast_cpu} 
    '''

}

PYTHON="$baseDir/vendor/python/bin/python"

coverages = Channel.create()
sortedIndexedBam = Channel.from(params.bam.split(',').collect{file(it)})

process bamToCoverage {
   
   cpus 2

   memory '4 GB'

   input: 
   val bam from sortedIndexedBam

   output:
   file "${bam.baseName}" into coverages
   
   when:
   bam != ''

   script:
   """
   #!/bin/sh
   $PYTHON ${baseDir}/scripts/bam_to_coverage.py ${bam} > ${bam.baseName}
   """
}

if(params.gff && params.contigs) {
    twoBitDir = outputDir
    indexFile = outputDir + "/index"
    chromFile = outputDir + "/chrom.sizes"
    gffFile = file(params.gff)
    gffInput = Channel.from(gffFile)
    gffContigFiles = Channel.create()
    contigsFile = file(params.contigs)
    assembly = Channel.create()

    Channel.fromPath(contigsFile)
         .splitFasta(file: "fa", by:50)
         .into(assembly)

    process faToTwoBit {

        cpus 2

        memory '1 GB'

        input:
        val assemblyChunk from assembly

        output:
        file "${twoBitDir}/${assemblyChunk.getName()}" into twoBits

        shell:
        '''
        #!/bin/sh
        !{params.faToTwoBit} '!{assemblyChunk}' '!{twoBitDir}/!{assemblyChunk.getName()}'
        rm '!{assemblyChunk}'
        '''
    }

    process prepareViewFiles {

       cpus 1

       memory '4 GB'

       input:
       val gffFile from gffInput

       output:
       file 'gff/*' into gffContigFiles mode flatten
       file "${indexFile}" into index

       script:
       """
       #!/bin/sh
       mkdir gff
       $PYTHON ${baseDir}/scripts/view_index.py --faa ${genomeFaa} --contigs ${contigsFile} --gff ${gffFile} --gffdir gff --out ${indexFile}
       """
    }


    process faSizes {

       cpus 1

       memory '4 GB'

       input:
       file contigsFile

       output:
       file "${chromFile}" into chromSizes

       script:
       """
       #!/bin/sh
       $PYTHON ${baseDir}/scripts/fa_sizes.py --fa ${contigsFile} --out ${chromFile}
       """
    }

    process gffToBed {

       cpus 1

       memory '4 GB'

       validExitStatus 0,255

       input:
       file gffFile from gffContigFiles
       file chromSizes

       script:
       """
       #!/bin/sh
       $PYTHON ${baseDir}/scripts/gff2bed.py --gff "${gffFile}" --bed "${outputDir}/${gffFile.baseName}.bed"
       bedToBigBed "${outputDir}/${gffFile.baseName}.bed" ${chromSizes} "${outputDir}/${gffFile.baseName}.bb"
       """
    }
    twoBits.collectFile();
}

coverageFiles = Channel.create()
coverages.collectFile().toList().into(coverageFiles)

uniq_overview = uniq_overview.collectFile()
process createOverview {

   cpus 2

   memory '4 GB'

   input:
   file blast_all
   file uniq_overview
   val coverageFiles

   output:
   val outputDir + '/overview.txt' into over

   shell:
   '''
   #!/bin/sh
   searchParam=""
   if [ -n !{params.search} ]
   then
       searchParam="--search=!{searchFile}"
   fi
   !{PYTHON} !{baseDir}/scripts/create_overview.py -u !{uniq_overview}  -faa !{baseDir} -o !{outputDir}  ${searchParam}  -c !{coverageFiles.join(' ')} 
   '''
}

process linkSearch {
   
   cpus 2

   memory '4 GB'

   input: 
   val x from over
   outputDir

   output:
   val outputDir into inputF 

   """
   #!/bin/sh
   $PYTHON $baseDir/scripts/link_search.py -o ${x} -out ${outputDir} 
   """
}


process folderToPubmed {
   
   executor 'local'
   
   cpus 2

   memory '4 GB'

   input:
   val inp from inputF
   outputDir

   output:
   val outputDir + '/all.pubHits'  into pub
   val outputDir + '/overview.txt' into over2

   shell:
   '''
   #!/bin/sh
   keywords=""
   if [ -f !{keywordsFile} ]
   then
         keywords=!{keywordsFile}
   else
         emptyKeywords="keywords.txt"
         touch $emptyKeywords 
         keywords=$emptyKeywords
   fi
   echo $keywords
   sh !{baseDir}/scripts/FolderToPubmed.sh !{inp} !{outputDir}  !{baseDir}/scripts/UrltoPubmedID.sh  ${keywords} 
   '''
}


process linkAssignment {
 
   cpus 2
 
   memory '6 GB'

   input:
   val x from over2
   val p from pub

   output:
   val outputDir + '/overview_new.txt' into overNew

   """
   #!/bin/sh
   $PYTHON $baseDir/scripts/link_assignment.py -o ${x} -pub ${p} 
   """
}

process buildHtml {

    cpus 2

    memory '3 GB'

    input:
    val overview from overNew

    output:
    stdout test

    shell:
    viewer = ""
    if(params.gff){
        viewer = "--viewer"
    }
    '''
    #!/bin/sh
    !{PYTHON} !{baseDir}/scripts/web/controller.py -o !{overview} -out !{outputDir} -conf !{baseDir}/scripts/web/config.yaml -templates !{baseDir}/scripts/web/app/templates !{viewer}
    '''
}

test.subscribe{
    print it
}