params.projectDir = './projects/prj_tmp'
params.readsDir   = "${params.projectDir}/samples/*.fastq.gz"
params.fastqcDir  = "${params.projectDir}/results/fastqc"
params.multiqcDir = "${params.projectDir}/results/multiqc"

Channel
    .fromPath( params.readsDir )
    .ifEmpty { error "Cannot find any reads matching: ${params.readsDir}" }
    .set {reads_for_fastqc}

process fastQC {
    publishDir params.fastqcDir, mode: 'copy'
    tag { "${reads}" }
    label 'big_mem' 

    input:
    path reads

    output:
   	path "*_fastqc.*"

    container 'biocontainers/fastqc:v0.11.9_cv8'
    script:
    """
        fastqc ${reads} 
    """
}

process multiQC {
    publishDir params.multiqcDir, mode: 'copy' 	// this time do not link but copy the output file

    input:
    path (inputfiles)

    output:
    path("multiqc_report.html")
    path("multiqc_data/multiqc_fastqc.txt")

    container 'quay.io/biocontainers/multiqc:1.21--pyhdfd78af_0'
    script:
    """
    multiqc .
    """
}

workflow {
    fastqc_out = fastQC(reads_for_fastqc)
    multiQC(fastqc_out.collect())
}

