version 1.0

import "../../../../common/wdl/tasks/fastp.wdl" as fastp_tasks
import "../../../../common/wdl/tasks/bwa.wdl" as bwa_tasks
import "../../../../common/wdl/tasks/samtools.wdl" as samtools_tasks
import "../../../../common/wdl/tasks/qualimap.wdl" as qualimap_tasks
import "../../../../common/wdl/tasks/mosdepth.wdl" as mosdepth_tasks

workflow preprocess_wf {

  input {

    File r1_fastq
    File r2_fastq

    File reference_fasta
    File reference_fai
    Array[File] bwa_index

    String sample_name

    File target_regions

    Int threads = 4
    Int ram_g = 4

  }

  call fastp_tasks.Fastp {

    input:
      r1_fastq = r1_fastq,
      r2_fastq = r2_fastq,
      sample_name = sample_name,
      threads = threads,
      ram_g = ram_g

  }

  call bwa_tasks.BwaMemPE {

    input:
      r1_fastq = Fastp.trimmed_r1,
      r2_fastq = Fastp.trimmed_r2,
      reference_fasta = reference_fasta,
      bwa_index = bwa_index,
      sample_name = sample_name,
      threads = threads

  }

  call samtools_tasks.SamtoolsSamToBam {

    input:
      sam = BwaMemPE.sam,
      sample_name = sample_name,
      threads = threads

  }

  call samtools_tasks.SamtoolsSortByCoordinate {

    input:
      bam = SamtoolsSamToBam.bam,
      sample_name = sample_name,
      threads = threads

  }

  call samtools_tasks.SamtoolsIndex {

    input:
      bam = SamtoolsSortByCoordinate.sorted_bam

  }

  call qualimap_tasks.QualimapBamQC {

    input:
      bam = SamtoolsSortByCoordinate.sorted_bam,
      bai = SamtoolsIndex.bai,
      target_regions = target_regions,
      sample_name = sample_name,
      threads = threads,
      ram_g = ram_g

  }

  call samtools_tasks.SamtoolsDepth {

    input:
      bam = SamtoolsSortByCoordinate.sorted_bam,
      bai = SamtoolsIndex.bai,
      targets_bed = target_regions,
      sample_name = sample_name,
      threads = threads,
      ram_g = ram_g

  }

  call mosdepth_tasks.MosdepthByTargets {

    input:
      bam = SamtoolsSortByCoordinate.sorted_bam,
      bai = SamtoolsIndex.bai,
      targets_bed = target_regions,
      sample_name = sample_name,
      threads = threads,
      ram_g = ram_g

  }

  output {

    # fastp_tasks.Fastp
    File trimmed_r1 = Fastp.trimmed_r1
    File trimmed_r2 = Fastp.trimmed_r2
    File fastp_html_report = Fastp.html_report
    File fastp_json_report = Fastp.json_report

    # bwa_tasks.BwaMemPE
    File sam = BwaMemPE.sam

    # samtools_tasks.SamtoolsSamToBam
    File unsorted_bam = SamtoolsSamToBam.bam

    # samtools_tasks.SamtoolsSortByCoordinate
    File coord_sorted_bam = SamtoolsSortByCoordinate.sorted_bam

    # samtools_tasks.SamtoolsIndex
    File coord_sorted_bai = SamtoolsIndex.bai

    # qualimap_tasks.QualimapBamQC
    # Directory qualimap_report_dir = QualimapBamQC.report_dir
    File qualimap_html_report = QualimapBamQC.html_report
    File qualimap_pdf_report = QualimapBamQC.pdf_report
    File qualimap_genome_results = QualimapBamQC.genome_results

    # SamtoolsDepth
    File samtools_depth_tsv = SamtoolsDepth.depth_tsv

    # MosdepthByTargets
    File mosdepth_summary = MosdepthByTargets.summary
    File mosdepth_regions_bed_gz = MosdepthByTargets.regions_bed_gz
    File mosdepth_thresholds_bed_gz = MosdepthByTargets.thresholds_bed_gz
    File mosdepth_global_dist = MosdepthByTargets.global_dist
    File mosdepth_region_dist = MosdepthByTargets.region_dist
    File mosdepth_per_base_bed_gz = MosdepthByTargets.per_base_bed_gz

  }

}

