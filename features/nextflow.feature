Feature: Verification steps for bioPipeline

  Scenario: Run the pipeline with --help
    When I run the command:
      """
      ${NEXTFLOW}/nextflow run ${PWD}/main.nf -profile 'local' --help
      """
    Then the exit code should be 0
    And the stdout should contain:
      """
      USAGE
      nextflow run metagenomics/MeRaGENE [OPTIONAL_ARGUMENTS] (--genome --ncbi --input --output --bam )
      """

  Scenario Outline: Run the pipeline with valid parameters
    Given I copy the example data files:
      | source           | dest        |
      | db.faa           | db.faa      |
      | blast.db         | blast.db    |
      | blast.db.phr     | blast.db.phr|
      | blast.db.psq     | blast.db.psq| 
      | blast.db.pin     | blast.db.pin|
      | test.bam         | test.bam    |
      | test.bam.bai     | test.bam.bai|
      | search.yaml      | search.yaml |
      | keywords.txt     | keywords.txt|
    And I copy the example data directories:
      | source           | dest        |
      | hmm              | hmm         |  
    When I run the command:
      """
        ${NEXTFLOW}/nextflow run ${PWD}/main.nf -profile 'local' \
         <faa> \
         <blast> \
         --blast_cpu=1 \
         --blastp="blastp" \
         --hmm_search="hmmsearch" \
         --hmm_scan="hmmscan" \
         --hmm_press="hmmpress" \
         <input> \
         <output> \
         <bam> \
         <search> \
         <keywords> \
      """
    Then the stderr should be empty
    And the exit code should be 0
    And the following files should exist and not be empty:
      | file                     |
      | output/overview.html     |
      | output/overview_new.txt  |
    And the file "output/overview_new.txt" should contain 6 lines
    Examples:
      | faa                              | blast                        | input                     | output                       | bam                         | search                             | keywords                             |
      | --genome="${PWD}/tmp/db.faa"     | --ncbi="${PWD}/tmp/blast.db" |  --input="${PWD}/tmp/hmm" | --output="${PWD}/tmp/output" | --bam="${PWD}/tmp/test.bam" |  --search="${PWD}/tmp/search.yaml" | --keywords="${PWD}/tmp/keywords.txt" |
      | --genome="db.faa"                | --ncbi="blast.db"            |  --input="hmm"            | --output="output"            | --bam="test.bam"            |  --search="search.yaml"            | --keywords="keywords.txt"  |