version 1.0

task SamtoolsSamToBam {

  input {

    File sam
    String sample_name

    Int threads = 8
    Int ram_g = 4
    String docker_image = "staphb/samtools:1.23"

  }

  command <<<

    mkdir samtools

    samtools view \
      -@ ~{threads} \
      -b \
      -o samtools/~{sample_name}.bam \
      ~{sam}

  >>>

  output {

    File bam = "samtools/~{sample_name}.bam"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}

task SamtoolsIndex {

  input {

    File bam

    Int threads = 4
    Int ram_g = 2
    String docker_image = "staphb/samtools:1.19"

  }

  String out_path = sub(basename(bam), "\.bam$", ".bai")

  command <<<

    mkdir samtools

    ln -s ~{bam}
    samtools index \
      -@ ~{threads} \
      $(basename ~{bam}) \
      samtools/~{out_path}

  >>>

  output {

    File bai = "samtools/~{out_path}"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}

task SamtoolsSortByCoordinate {

  input {

    File bam
    String sample_name

    Int threads = 8
    Int ram_g = 8
    String docker_image = "staphb/samtools:1.19"

  }

  command <<<

    mkdir samtools

    samtools sort \
      -@ ~{threads} \
      -o samtools/~{sample_name}.coord_sorted.bam \
      ~{bam}

  >>>

  output {

    File sorted_bam = "samtools/~{sample_name}.coord_sorted.bam"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}


task SamtoolsSortByName {

  input {

    File bam
    String sample_name

    Int threads = 8
    Int ram_g = 8
    String docker_image = "staphb/samtools:1.19"

  }

  command <<<

    mkdir samtools

    samtools sort \
      -@ ~{threads} \
      -n \
      -o samtools/~{sample_name}.name_sorted.bam \
      ~{bam}

  >>>

  output {

    File name_sorted_bam = "samtools/~{sample_name}.name_sorted.bam"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}


task SamtoolsDepth {

  input {

    File bam
    File bai
    File targets_bed
    String sample_name

    Int threads = 4
    Int ram_g = 4
    String docker_image = "staphb/samtools:1.19"

  }

  command <<<

    mkdir samtools

    samtools depth \
      -@ ~{threads} \
      -a \
      -b ~{targets_bed} \
      ~{bam} \
      > samtools/~{sample_name}.samtools.depth.tsv

  >>>

  output {

    File depth_tsv = "samtools/~{sample_name}.samtools.depth.tsv"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}
