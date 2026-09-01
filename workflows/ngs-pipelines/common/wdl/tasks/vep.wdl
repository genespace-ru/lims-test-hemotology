version 1.0

task VepAnnotate {

  input {
    File input_vcf
    File input_vcf_index

    File reference_fasta
    File vep_cache_dir

    String output_prefix

    Int threads = 1
    Int ram_g = 8

    String cache_version = "116"
    String assembly = "GRCh38"
    String species = "homo_sapiens"

    String docker_image = "ensemblorg/ensembl-vep:release_116.0"
  }

  command <<<

    mkdir vep/

    tar -xzf ~{vep_cache_dir}

    vep \
      --input_file ~{input_vcf} \
      --output_file vep/~{output_prefix}.vep.vcf.gz \
      --stats_file vep/~{output_prefix}.vep.summary.html \
      --vcf \
      --compress_output bgzip \
      --force_overwrite \
      --offline \
      --cache \
      --dir_cache vep_cache \
      --cache_version ~{cache_version} \
      --assembly ~{assembly} \
      --species ~{species} \
      --fasta ~{reference_fasta} \
      --fork ~{threads} \
      --check_existing \
      --symbol \
      --mane \
      --pick \
      --pick_order mane_select \
      --hgvs \
      --numbers \
      --af \
      --af_gnomade \
      --af_gnomadg

    tabix \
      -f \
      -p vcf \
      vep/~{output_prefix}.vep.vcf.gz

  >>>

  output {
    File annotated_vcf = "vep/~{output_prefix}.vep.vcf.gz"
    File annotated_vcf_index = "vep/~{output_prefix}.vep.vcf.gz.tbi"
    File summary_html = "vep/~{output_prefix}.vep.summary.html"
  }

  runtime {
    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"
  }
}
