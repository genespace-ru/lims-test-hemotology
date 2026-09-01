version 1.0

# workflow imports
import "preprocess.wdl" as preprocess

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

    File vep_cache_dir

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

  output {

    File tumor_bam = PrepareTumorBam.coord_sorted_bam
    File tumor_bai = PrepareTumorBam.coord_sorted_bai
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

  }
}

