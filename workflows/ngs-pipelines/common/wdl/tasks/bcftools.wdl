version 1.0

task FilterGermlineVariants {
  input {
    File input_vcf
    File input_vcf_index

    String sample_name
    String output_prefix

    Int min_dp = 30
    Int min_gq = 20
    Float min_vaf_het = 0.25
    Float max_vaf_het = 0.75
    Float min_vaf_hom = 0.85

    String docker_image = "staphb/bcftools:1.19"
  }

  command <<<

    mkdir bcftools

    bcftools view \
      -s ~{sample_name} \
      -i 'FILTER="PASS" && FORMAT/DP[0] >= ~{min_dp} && FORMAT/GQ[0] >= ~{min_gq} && ((GT="het" && FORMAT/VAF[0:0] >= ~{min_vaf_het} && FORMAT/VAF[0:0] <= ~{max_vaf_het}) || (GT="hom" && FORMAT/VAF[0:0] >= ~{min_vaf_hom}))' \
      ~{input_vcf} \
      -Oz -o bcftools/~{output_prefix}.germline.filtered.vcf.gz

    bcftools index -t bcftools/~{output_prefix}.germline.filtered.vcf.gz
  >>>

  output {
    File filtered_vcf = "bcftools/~{output_prefix}.germline.filtered.vcf.gz"
    File filtered_vcf_index = "bcftools/~{output_prefix}.germline.filtered.vcf.gz.tbi"
  }

  runtime {
    docker: docker_image
  }
}


task FilterSomaticVariants {
  input {
    File input_vcf
    File input_vcf_index

    String tumor_sample_name
    String normal_sample_name
    String output_prefix

    Int min_tumor_dp = 100
    Int min_normal_dp = 30
    Float min_tumor_af = 0.05
    Float max_normal_af = 0.02

    String docker_image = "staphb/bcftools:1.19"
  }

  command <<<

    mkdir bcftools

    bcftools view \
      -s ~{tumor_sample_name},~{normal_sample_name} \
      -i 'FILTER="PASS" && FORMAT/DP[0] >= ~{min_tumor_dp} && FORMAT/DP[1] >= ~{min_normal_dp} && FORMAT/AF[0:0] >= ~{min_tumor_af} && FORMAT/AF[1:0] <= ~{max_normal_af}' \
      ~{input_vcf} \
      -Oz -o bcftools/~{output_prefix}.somatic.filtered.vcf.gz

    bcftools index -t bcftools/~{output_prefix}.somatic.filtered.vcf.gz
  >>>

  output {
    File filtered_vcf = "bcftools/~{output_prefix}.somatic.filtered.vcf.gz"
    File filtered_vcf_index = "bcftools/~{output_prefix}.somatic.filtered.vcf.gz.tbi"
  }

  runtime {
    docker: docker_image
  }
}

task BcftoolsStats {
  input {
    File input_vcf
    File input_vcf_index

    String output_prefix

    String docker_image = "staphb/bcftools:1.19"
  }

  command <<<

    mkdir bcftools

    bcftools stats \
      ~{input_vcf} \
      > bcftools/~{output_prefix}.bcftools.stats.txt

  >>>

  output {
    File stats = "bcftools/~{output_prefix}.bcftools.stats.txt"
  }

  runtime {
    docker: docker_image
  }
}

