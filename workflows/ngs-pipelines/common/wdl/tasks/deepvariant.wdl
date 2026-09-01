version 1.0

task DeepVariantGermline {

  input {

    File bam
    File bai

    File reference_fasta
    File reference_fai

    File targets_bed
    String sample_name

    Int threads = 4
    Int ram_g = 4

    String model_type = "WES"
    String docker_image = "google/deepvariant:1.10.0"

  }

  command <<<

    mkdir deepvariant/

    BAM=$(basename ~{bam})
    REF=$(basename ~{reference_fasta})

    ln -s ~{bam} $BAM
    ln -s ~{bai} $BAM.bai

    ln -s ~{reference_fasta} $REF
    ln -s ~{reference_fai} $REF.fai

    run_deepvariant \
      --model_type=~{model_type} \
      --ref=$REF \
      --reads=$BAM \
      --regions=~{targets_bed} \
      --output_vcf=deepvariant/~{sample_name}.deepvariant.vcf.gz \
      --output_gvcf=deepvariant/~{sample_name}.deepvariant.g.vcf.gz \
      --num_shards=~{threads}

  >>>

  output {

    File vcf_gz = "deepvariant/~{sample_name}.deepvariant.vcf.gz"
    File vcf_gz_tbi = "deepvariant/~{sample_name}.deepvariant.vcf.gz.tbi"

    File gvcf_gz = "deepvariant/~{sample_name}.deepvariant.g.vcf.gz"
    File gvcf_gz_tbi = "deepvariant/~{sample_name}.deepvariant.g.vcf.gz.tbi"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}
