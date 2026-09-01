version 1.0

# workflow imports
import "preprocess.wdl" as preprocess
import "somatic.wdl" as somatic
import "germline.wdl" as germline

# task imports
import "../../../../common/wdl/tasks/multiqc.wdl" as multiqc_tasks
import "../../../../common/wdl/tasks/bcftools.wdl" as bcftools_tasks

workflow BRCA_full_wf {

  input {

    File tumor_r1_fastq
    File tumor_r2_fastq
    File normal_r1_fastq
    File normal_r2_fastq

    String tumor_sample_name
    String normal_sample_name

    File reference_fasta
    File reference_fai
    File reference_dict
    Array[File] bwa_index

    File target_regions

    Int threads = 4
    Int ram_g = 8

  }

  call preprocess.preprocess_wf as PrepareTumorBam {

    input:
      r1_fastq = tumor_r1_fastq,
      r2_fastq = tumor_r2_fastq,
      sample_name = tumor_sample_name,
      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      bwa_index = bwa_index,
      target_regions = target_regions,
      threads = threads,
      ram_g = ram_g

  }

  call preprocess.preprocess_wf as PrepareNormalBam {

    input:
      r1_fastq = normal_r1_fastq,
      r2_fastq = normal_r2_fastq,
      sample_name = normal_sample_name,
      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      bwa_index = bwa_index,
      target_regions = target_regions,
      threads = threads,
      ram_g = ram_g

  }

  call somatic.somatic_wf {

    input:
      tumor_bam = PrepareTumorBam.coord_sorted_bam,
      tumor_bai = PrepareTumorBam.coord_sorted_bai,
      normal_bam = PrepareNormalBam.coord_sorted_bam,
      normal_bai = PrepareNormalBam.coord_sorted_bai,
      tumor_sample_name = tumor_sample_name,
      normal_sample_name = normal_sample_name,
      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      reference_dict = reference_dict,
      target_regions = target_regions,
      ram_g = ram_g

  }

  call germline.germline_wf {

    input:
      coord_sorted_bam = PrepareNormalBam.coord_sorted_bam,
      coord_sorted_bai = PrepareNormalBam.coord_sorted_bai,
      sample_name = normal_sample_name,
      reference_fasta = reference_fasta,
      reference_fai = reference_fai,
      target_regions = target_regions,
      threads = threads,
      ram_g = ram_g

  }


## TODO: перенести вызовы тасок в отдельные ворклоу somatic и germline
call bcftools_tasks.FilterGermlineVariants {
  input:
    input_vcf = germline_wf.deepvariant_vcf_gz,
    input_vcf_index = germline_wf.deepvariant_vcf_gz_tbi,
    sample_name = normal_sample_name,
    output_prefix = normal_sample_name
}

call bcftools_tasks.BcftoolsStats as GermlineBcftoolsStats {
  input:
    input_vcf = FilterGermlineVariants.filtered_vcf,
    input_vcf_index = FilterGermlineVariants.filtered_vcf_index,
    output_prefix = normal_sample_name + ".germline.filtered"
}

call bcftools_tasks.FilterSomaticVariants {
  input:
    input_vcf = somatic_wf.mutect2_filtered_vcf,
    input_vcf_index = somatic_wf.mutect2_filtered_vcf_index,
    tumor_sample_name = tumor_sample_name,
    normal_sample_name = normal_sample_name,
    output_prefix = tumor_sample_name + "_vs_" + normal_sample_name
}

call bcftools_tasks.BcftoolsStats as SomaticBcftoolsStats {
  input:
    input_vcf = FilterSomaticVariants.filtered_vcf,
    input_vcf_index = FilterSomaticVariants.filtered_vcf_index,
    output_prefix = tumor_sample_name + "_vs_" + normal_sample_name + ".somatic.filtered"
}
##

  call multiqc_tasks.MultiQC {
    input:
      qc_files = [
        PrepareTumorBam.fastp_json_report,
        PrepareTumorBam.qualimap_genome_results,
        PrepareTumorBam.mosdepth_summary,
        PrepareTumorBam.mosdepth_global_dist,
        PrepareTumorBam.mosdepth_region_dist,

        PrepareNormalBam.fastp_json_report,
        PrepareNormalBam.qualimap_genome_results,
        PrepareNormalBam.mosdepth_summary,
        PrepareNormalBam.mosdepth_global_dist,
        PrepareNormalBam.mosdepth_region_dist,

        SomaticBcftoolsStats.stats,
        GermlineBcftoolsStats.stats
      ],
      output_prefix = tumor_sample_name + "_vs_" + normal_sample_name,
      ram_g = ram_g
  }

  output {

    File tumor_bam = PrepareTumorBam.coord_sorted_bam
    File tumor_bai = PrepareTumorBam.coord_sorted_bai

    File normal_bam = PrepareNormalBam.coord_sorted_bam
    File normal_bai = PrepareNormalBam.coord_sorted_bai

    File somatic_vcf = somatic_wf.mutect2_filtered_vcf
    File somatic_vcf_index = somatic_wf.mutect2_filtered_vcf_index

    File germline_vcf = germline_wf.deepvariant_vcf_gz
    File germline_vcf_index = germline_wf.deepvariant_vcf_gz_tbi

    # Reports
    ## Tumor reports
    ### qualimap_tasks.QualimapBamQC
    File tumor_qualimap_html_report = PrepareTumorBam.qualimap_html_report
    File tumor_qualimap_pdf_report = PrepareTumorBam.qualimap_pdf_report
    File tumor_qualimap_genome_results = PrepareTumorBam.qualimap_genome_results

    ### SamtoolsDepth
    File tumor_samtools_depth_tsv = PrepareTumorBam.samtools_depth_tsv

    ### MosdepthByTargets
    File tumor_mosdepth_summary = PrepareTumorBam.mosdepth_summary
    File tumor_mosdepth_regions_bed_gz = PrepareTumorBam.mosdepth_regions_bed_gz
    File tumor_mosdepth_thresholds_bed_gz = PrepareTumorBam.mosdepth_thresholds_bed_gz
    File tumor_mosdepth_global_dist = PrepareTumorBam.mosdepth_global_dist
    File tumor_mosdepth_region_dist = PrepareTumorBam.mosdepth_region_dist
    File tumor_mosdepth_per_base_bed_gz = PrepareTumorBam.mosdepth_per_base_bed_gz

    ## Normal reports
    ### qualimap_tasks.QualimapBamQC
    File normal_qualimap_html_report = PrepareNormalBam.qualimap_html_report
    File normal_qualimap_pdf_report = PrepareNormalBam.qualimap_pdf_report
    File normal_qualimap_genome_results = PrepareNormalBam.qualimap_genome_results

    ### SamtoolsDepth
    File normal_samtools_depth_tsv = PrepareNormalBam.samtools_depth_tsv

    ### MosdepthByTargets
    File normal_mosdepth_summary = PrepareNormalBam.mosdepth_summary
    File normal_mosdepth_regions_bed_gz = PrepareNormalBam.mosdepth_regions_bed_gz
    File normal_mosdepth_thresholds_bed_gz = PrepareNormalBam.mosdepth_thresholds_bed_gz
    File normal_mosdepth_global_dist = PrepareNormalBam.mosdepth_global_dist
    File normal_mosdepth_region_dist = PrepareNormalBam.mosdepth_region_dist
    File normal_mosdepth_per_base_bed_gz = PrepareNormalBam.mosdepth_per_base_bed_gz

    ### FilterGermlineVariants 
    File germline_filtered_vcf = FilterGermlineVariants.filtered_vcf
    File germline_filtered_vcf_index = FilterGermlineVariants.filtered_vcf_index

    ### GermlineBcftoolsStats
    File germline_bcftools_stats = GermlineBcftoolsStats.stats

    ###FilterSomaticVariants
    File somatic_filtered_vcf = FilterSomaticVariants.filtered_vcf
    File somatic_filtered_vcf_index = FilterSomaticVariants.filtered_vcf_index

    ### SomaticBcftoolsStats
    File somatic_bcftools_stats = SomaticBcftoolsStats.stats

    # MultiQC
    File multiqc_html_report = MultiQC.html_report
    File multiqc_json_data = MultiQC.json_data
    File multiqc_sources = MultiQC.sources
    Array[File] multiqc_data_files = MultiQC.data_files

  }
}

