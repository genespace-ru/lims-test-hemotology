nextflow.enable.dsl=2
include { toChannel; prefix_wdl; fileOrNull; get; toArray; range; getDefault; combineAll; pair; stringify_wdl; saveOutput; orNull } from './genespace_function.nf'
include ( FilterSomaticVariants as bcftools_tasks ) from 'bcftools.wdl'
include ( preprocess_wf as preprocess ) from 'preprocess.wdl'
include ( VepAnnotate as vep_tasks ) from 'vep.wdl'
include ( somatic_wf as somatic ) from 'somatic.wdl'
include ( germline_wf as germline ) from 'germline.wdl'
include ( MultiQC as multiqc_tasks ) from 'multiqc.wdl'
params.tumor_r1_fastq = "NO_VALUE"
params.tumor_r2_fastq = "NO_VALUE"
params.normal_r1_fastq = "NO_VALUE"
params.normal_r2_fastq = "NO_VALUE"
params.tumor_sample_name = "NO_VALUE"
params.normal_sample_name = "NO_VALUE"
params.reference_fasta = "NO_VALUE"
params.reference_fai = "NO_VALUE"
params.reference_dict = "NO_VALUE"
params.bwa_index = "NO_VALUE"
params.target_regions = "NO_VALUE"
params.vep_cache_dir = vep_cache_dir
params.threads = 4
params.ram_g = 8

workflow BRCA_full_wf {

  take:
  tumor_r1_fastq
  tumor_r2_fastq
  normal_r1_fastq
  normal_r2_fastq
  tumor_sample_name
  normal_sample_name
  reference_fasta
  reference_fai
  reference_dict
  bwa_index
  target_regions
  vep_cache_dir
  threads
  ram_g

  main:
  PrepareNormalBam( normal_r1_fastq normal_r2_fastq reference_fasta reference_fai bwa_index normal_sample_name target_regions threads ram_g )

  germline_wf( PrepareNormalBam.out.coord_sorted_bam PrepareNormalBam.out.coord_sorted_bai reference_fasta reference_fai normal_sample_name target_regions threads ram_g )

  PrepareTumorBam( tumor_r1_fastq tumor_r2_fastq reference_fasta reference_fai bwa_index tumor_sample_name target_regions threads ram_g )

  somatic_wf( PrepareTumorBam.out.coord_sorted_bam PrepareTumorBam.out.coord_sorted_bai PrepareNormalBam.out.coord_sorted_bam PrepareNormalBam.out.coord_sorted_bai reference_fasta reference_fai reference_dict tumor_sample_name normal_sample_name target_regions 4 ram_g )

  AnnotateSomatic( somatic_wf.out.mutect2_filtered_vcf somatic_wf.out.mutect2_filtered_vcf_index reference_fasta vep_cache_dir tumor_sample_name+"_vs_"+normal_sample_name+".somatic" 1 ram_g "116" "GRCh38" "homo_sapiens" "ensemblorg/ensembl-vep:release_116.0" )

  FilterGermlineVariants( germline_wf.out.deepvariant_vcf_gz germline_wf.out.deepvariant_vcf_gz_tbi normal_sample_name normal_sample_name 30 20 0.25 0.75 0.85 "staphb/bcftools:1.19" )

  AnnotateGermline( germline_wf.out.deepvariant_vcf_gz germline_wf.out.deepvariant_vcf_gz_tbi reference_fasta vep_cache_dir normal_sample_name+".germline" 1 ram_g "116" "GRCh38" "homo_sapiens" "ensemblorg/ensembl-vep:release_116.0" )

  FilterSomaticVariants( somatic_wf.out.mutect2_filtered_vcf somatic_wf.out.mutect2_filtered_vcf_index tumor_sample_name normal_sample_name tumor_sample_name+"_vs_"+normal_sample_name 100 30 0.05 0.02 "staphb/bcftools:1.19" )

  GermlineBcftoolsStats( FilterGermlineVariants.out.filtered_vcf FilterGermlineVariants.out.filtered_vcf_index normal_sample_name+".germline.filtered" "staphb/bcftools:1.19" )

  SomaticBcftoolsStats( FilterSomaticVariants.out.filtered_vcf FilterSomaticVariants.out.filtered_vcf_index tumor_sample_name+"_vs_"+normal_sample_name+".somatic.filtered" "staphb/bcftools:1.19" )

  MultiQC( toArray([
PrepareTumorBam.out.out.out.out.out.fastp_json_report,
PrepareTumorBam.out.out.out.out.out.qualimap_genome_results,
PrepareTumorBam.out.out.out.out.out.mosdepth_summary,
PrepareTumorBam.out.out.out.out.out.mosdepth_global_dist,
PrepareTumorBam.out.out.out.out.out.mosdepth_region_dist,

PrepareNormalBam.out.out.out.out.out.fastp_json_report,
PrepareNormalBam.out.out.out.out.out.qualimap_genome_results,
PrepareNormalBam.out.out.out.out.out.mosdepth_summary,
PrepareNormalBam.out.out.out.out.out.mosdepth_global_dist,
PrepareNormalBam.out.out.out.out.out.mosdepth_region_dist,

SomaticBcftoolsStats.out.stats,
GermlineBcftoolsStats.out.stats
]) tumor_sample_name+"_vs_"+normal_sample_name ram_g "multiqc/multiqc:v1.29" )

  emit: 
  germline_bcftools_stats = GermlineBcftoolsStats.out.stats
  germline_filtered_vcf = FilterGermlineVariants.out.filtered_vcf
  germline_filtered_vcf_index = FilterGermlineVariants.out.filtered_vcf_index
  germline_vcf = germline_wf.out.deepvariant_vcf_gz
  germline_vcf_index = germline_wf.out.deepvariant_vcf_gz_tbi
  germline_vep_summary = AnnotateGermline.out.summary_html
  germline_vep_vcf = AnnotateGermline.out.annotated_vcf
  germline_vep_vcf_index = AnnotateGermline.out.annotated_vcf_index
  multiqc_data_files = MultiQC.out.data_files
  multiqc_html_report = MultiQC.out.html_report
  multiqc_json_data = MultiQC.out.json_data
  multiqc_sources = MultiQC.out.sources
  normal_bai = PrepareNormalBam.out.coord_sorted_bai
  normal_bam = PrepareNormalBam.out.coord_sorted_bam
  normal_mosdepth_global_dist = PrepareNormalBam.out.mosdepth_global_dist
  normal_mosdepth_per_base_bed_gz = PrepareNormalBam.out.mosdepth_per_base_bed_gz
  normal_mosdepth_region_dist = PrepareNormalBam.out.mosdepth_region_dist
  normal_mosdepth_regions_bed_gz = PrepareNormalBam.out.mosdepth_regions_bed_gz
  normal_mosdepth_summary = PrepareNormalBam.out.mosdepth_summary
  normal_mosdepth_thresholds_bed_gz = PrepareNormalBam.out.mosdepth_thresholds_bed_gz
  normal_qualimap_genome_results = PrepareNormalBam.out.qualimap_genome_results
  normal_qualimap_html_report = PrepareNormalBam.out.qualimap_html_report
  normal_qualimap_pdf_report = PrepareNormalBam.out.qualimap_pdf_report
  normal_samtools_depth_tsv = PrepareNormalBam.out.samtools_depth_tsv
  somatic_bcftools_stats = SomaticBcftoolsStats.out.stats
  somatic_filtered_vcf = FilterSomaticVariants.out.filtered_vcf
  somatic_filtered_vcf_index = FilterSomaticVariants.out.filtered_vcf_index
  somatic_vcf = somatic_wf.out.mutect2_filtered_vcf
  somatic_vcf_index = somatic_wf.out.mutect2_filtered_vcf_index
  somatic_vep_summary = AnnotateSomatic.out.summary_html
  somatic_vep_vcf = AnnotateSomatic.out.annotated_vcf
  somatic_vep_vcf_index = AnnotateSomatic.out.annotated_vcf_index
  tumor_bai = PrepareTumorBam.out.coord_sorted_bai
  tumor_bam = PrepareTumorBam.out.coord_sorted_bam
  tumor_mosdepth_global_dist = PrepareTumorBam.out.mosdepth_global_dist
  tumor_mosdepth_per_base_bed_gz = PrepareTumorBam.out.mosdepth_per_base_bed_gz
  tumor_mosdepth_region_dist = PrepareTumorBam.out.mosdepth_region_dist
  tumor_mosdepth_regions_bed_gz = PrepareTumorBam.out.mosdepth_regions_bed_gz
  tumor_mosdepth_summary = PrepareTumorBam.out.mosdepth_summary
  tumor_mosdepth_thresholds_bed_gz = PrepareTumorBam.out.mosdepth_thresholds_bed_gz
  tumor_qualimap_genome_results = PrepareTumorBam.out.qualimap_genome_results
  tumor_qualimap_html_report = PrepareTumorBam.out.qualimap_html_report
  tumor_qualimap_pdf_report = PrepareTumorBam.out.qualimap_pdf_report
  tumor_samtools_depth_tsv = PrepareTumorBam.out.samtools_depth_tsv
}

workflow {
BRCA_full_wf ( fileOrNull( params.tumor_r1_fastq) fileOrNull( params.tumor_r2_fastq) fileOrNull( params.normal_r1_fastq) fileOrNull( params.normal_r2_fastq) params.tumor_sample_name params.normal_sample_name fileOrNull( params.reference_fasta) fileOrNull( params.reference_fai) fileOrNull( params.reference_dict) params.bwa_index.collect { file(it) } fileOrNull( params.target_regions) fileOrNull( params.vep_cache_dir) params.threads params.ram_g  )

}