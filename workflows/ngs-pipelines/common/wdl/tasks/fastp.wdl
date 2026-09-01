version 1.0

task Fastp {

  input {

    File r1_fastq
    File r2_fastq

    String sample_name
    Int threads = 8
    Int ram_g = 4
    String docker_image = "staphb/fastp:1.3.3"

  }

  command <<<

    fastp \
    -i ~{r1_fastq} \
    -I ~{r2_fastq} \
    -o ~{sample_name}.R1.fastp.fq.gz \
    -O ~{sample_name}.R2.fastp.fq.gz \
    --detect_adapter_for_pe \
    --html ~{sample_name}.fastp.html \
    --json ~{sample_name}.fastp.json \
    --thread ~{threads}

    mkdir fastp
    mv *fq.gz fastp/
    mv ~{sample_name}.fastp.html fastp/
    mv ~{sample_name}.fastp.json fastp/

  >>>

  output {

    File trimmed_r1 = "fastp/~{sample_name}.R1.fastp.fq.gz"
    File trimmed_r2 = "fastp/~{sample_name}.R2.fastp.fq.gz"

    File html_report = "fastp/~{sample_name}.fastp.html"
    File json_report = "fastp/~{sample_name}.fastp.json"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}
