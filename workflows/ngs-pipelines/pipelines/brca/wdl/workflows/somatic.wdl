version 1.0

import "../../../../common/wdl/tasks/mutect2.wdl" as mutect2_tasks

workflow somatic_wf {

  input {

    File tumor_bam
    File tumor_bai
    File normal_bam
    File normal_bai

    File reference_fasta
    File reference_fai
    File reference_dict

    String tumor_sample_name
    String normal_sample_name

    File target_regions

    Int threads = 4
    Int ram_g = 4

  }
 
  call mutect2_tasks.Mutect2TumorNormal {

    input:
      tumor_bam = tumor_bam,
      tumor_bai = tumor_bai,
      normal_bam = normal_bam,
      normal_bai = normal_bai,

      tumor_sample_name = tumor_sample_name,
      normal_sample_name = normal_sample_name,

      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      reference_dict = reference_dict,
      target_regions = target_regions,

      output_prefix = tumor_sample_name + "_vs_" + normal_sample_name,
      ram_g = ram_g

  }

  call mutect2_tasks.FilterMutectCalls {

    input:
      vcf = Mutect2TumorNormal.vcf,
      vcf_index = Mutect2TumorNormal.vcf_index,
      stats = Mutect2TumorNormal.stats,

      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      reference_dict = reference_dict,

      output_prefix = tumor_sample_name + "_vs_" + normal_sample_name,
      ram_g = ram_g
 
  }

  output {

    # Mutect2
    File mutect2_unfiltered_vcf = Mutect2TumorNormal.vcf
    File mutect2_unfiltered_vcf_index = Mutect2TumorNormal.vcf_index
    File mutect2_stats = Mutect2TumorNormal.stats

    #  
    File mutect2_filtered_vcf = FilterMutectCalls.vcf_filtered
    File mutect2_filtered_vcf_index = FilterMutectCalls.vcf_filtered_index

  }

}

