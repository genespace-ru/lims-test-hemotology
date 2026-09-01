version 1.0

import "../../../../common/wdl/tasks/deepvariant.wdl" as deepvariant_tasks

workflow germline_wf {

  input {

    File coord_sorted_bam
    File coord_sorted_bai

    File reference_fasta
    File reference_fai

    String sample_name

    File target_regions

    Int threads = 4
    Int ram_g = 4

  }

  call deepvariant_tasks.DeepVariantGermline {

    input:

      bam = coord_sorted_bam,
      bai = coord_sorted_bai,
      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      targets_bed = target_regions,
      sample_name = sample_name,
      threads = threads,
      ram_g = ram_g

  }

  output {

    # DeepVariantGermline
    File deepvariant_vcf_gz = DeepVariantGermline.vcf_gz
    File deepvariant_vcf_gz_tbi = DeepVariantGermline.vcf_gz_tbi
    File deepvariant_gvcf_gz = DeepVariantGermline.gvcf_gz
    File deepvariant_gvcf_gz_tbi = DeepVariantGermline.gvcf_gz_tbi

  }

}

