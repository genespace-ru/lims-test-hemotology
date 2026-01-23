params.allReads = "${params.readsDir}/*.fastq.gz"
Channel
    .fromPath( params.allReads )
    .ifEmpty { error "Cannot find any reads matching: ${params.allReads}" }
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

process parseMultyQC {
    input:
    path (inputfiles)

    script:
    """
    	curl -H "Content-Type: application/json" --data '{${params.parseData},"results":"${params.multiqcDir}/multiqc_data/multiqc_fastqc.txt", "report":"${params.multiqcDir}/multiqc_report.html"}' ${params.parseUrl}
    """

}

workflow {
    fastqc_out = fastQC(reads_for_fastqc)
    multiQC_out = multiQC(fastqc_out.collect())
    parseMultyQC("${params.multiqcDir}/multiqc_data_multiqc_fastqc.txt")
}

