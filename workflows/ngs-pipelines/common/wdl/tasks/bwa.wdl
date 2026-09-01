version 1.0

task BwaMemPE {

  input {

    File r1_fastq
    File r2_fastq

    File reference_fasta
    Array[File] bwa_index

    String sample_name
    String read_group_id = sample_name
    String platform = "ILLUMINA"
    String library = ""
    String platform_unit = ""

    Int threads = 8
    Int ram_g = 8

    String docker_image = "staphb/bwa:0.7.19"

  }

  command <<<

    mkdir bwa-mem

    ln -s ~{reference_fasta} .
    for file in ~{sep=' ' bwa_index}; do
      ln -s $file .
    done

    RG="@RG\tID:~{read_group_id}\tSM:~{sample_name}\tPL:~{platform}"

    if [ -n "~{library}" ]; then
      RG="${RG}\tLB:~{library}"
    fi

    if [ -n "~{platform_unit}" ]; then
      RG="${RG}\tPU:~{platform_unit}"
    fi

    bwa mem \
      -t ~{threads} \
      -R "$RG" \
      $(basename ~{reference_fasta}) \
      ~{r1_fastq} \
      ~{r2_fastq} \
      > bwa-mem/~{sample_name}.bwa_mem.sam

  >>>

  output {

    File sam = "bwa-mem/~{sample_name}.bwa_mem.sam"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}
