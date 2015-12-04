[![Circle CI](https://circleci.com/gh/metagenomics/MeRaGENE/tree/master.svg?style=svg)](https://circleci.com/gh/metagenomics/MeRaGENE/tree/master)

# **MeRaGENE**

### Introduction

MeRaGENE (Metagenomics rapid gene identification pipeline) is based on profile Hidden-Markov-Models (pHMM) which can be build from any gene set. Furthermore it allows to scale on a single multicore machine and also on different cluster systems. MeRaGENE first scans the metagenome dataset for similarities to the predefined pHMMs. To verify the identified hits, a BLASTp search on the NCBI nr database is performed. Multiple settings like E-value thresholds, gene coverage, etc. are tested to further enhance the reliability of identified hits.
Finally, all results are summarized in one HTML file and visualized in charts. This allows to explore results easier and thereby optimizes the interpretation of findings.

**MeRaGENE** produces results like the following example:
http://metagenomics.github.io/MeRaGENE/

### Quickstart

1. create a new folder for nextflow to work in 
2. switch to this new folder
3. create a new .txt document
4. fill it with keywords, one word per line.
  publications associated with your blast hits will be scanned for these keywords
5. open a shell 
6. type in `"curl -fsSL get.nextflow.io | bash"` to download nextflow into this folder
7. make sure that the binaries stated in the **Requirements** section below are installed on your machine
8. after nextflow is downloaded, replace all the `"YOUR_***"` parts in the following command with your own paths 
  - `"./nextflow run main.nf --genome="YOUR_FAA_FILE_OF_A_METAGENOME" --ncbi="YOUR_BLAST-DB" --input="YOUR_INPUT-HMM_FOLDER" --output="YOUR_OUTPUT-FOLDER" --bam="READ_ASSEMBLY_ALIGNMENT" --keywords="YOUR_KEYWORD-FILE"`
9. after replacing everything, run your command
10. that's it ! The pipeline is running and crunching your data. Look for the overview.txt or. overview_new.txt in your output folder after the pipeline is finished
- if you have further questions:
   - read the additional settings section down below 
   - search our documentation 
   - contact us via mail

### Requirements

 - Blast (>2.2.28)
 - hmmsearch 3.0
 - Header in .faa file must be unique and without whitespace
 - blastdb must be the official ncbi nr database.
 - samtools

### [Change Log](CHANGELOG.md)

### Additional settings

If you want/have to make further changes to your pipeline, here are all possibilities: [usage](usage.txt)
 
### Update MeRaGENE

If you have already MeRaGENE installed, just run 

~~~
nextflow drop -f metagenomics/MeRaGENE
nextflow pull metagenomics/MeRaGENE 
~~~

### E-Mail
Contact us, if you have further questions:
`pbelmann@cebitec.uni-bielefeld.de`

## Development Guide

This project uses the [GitHub flow](https://guides.github.com/introduction/flow/). The basic idea of the 
this workflow is that the master branch provides always a working version of the project.
Please name your branches according to the following pattern:

`type/name`

Where `type` can be `feature` or `fix` and `name` is a short description of the branch.

Example: `feature/development-guide`

Merge a branch by providing a pull request to a release/x.x.x branch. Please update the [change log](CHANGELOG.md) before merging.

### Development Scripts

The folder `controls` provides a series of scripts to help developers and also
used by the continuous integration server. 

  * `controls/install`: Install required python libraries using virtual env and requirements.txt.

  * `controls/test`: Runs python unit tests (requires previous run of `controls/install`)
  
  * `controls/feature`: Runs feature tests (requires previous run of `controls/install`) 
  
