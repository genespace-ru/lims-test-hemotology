version 1.0

task QualimapBamQC {

  input {

    File bam
    File bai
    File target_regions

    String sample_name

    Int threads = 2
    Int ram_g = 6
    String docker_image = "staphb/qualimap:2.3"

  }

  command <<<

    qualimap bamqc \
      -bam ~{bam} \
      -gff ~{target_regions} \
      -outdir ~{sample_name}.qualimap_bamqc \
      -outformat PDF:HTML \
      -nt ~{threads} \
      --java-mem-size=~{ram_g}G

      mv ~{sample_name}.qualimap_bamqc/report.pdf ~{sample_name}.qualimap_bamqc/qualimapReport.pdf
  >>>

  output {

    # Directory report_dir = "~{sample_name}.qualimap_bamqc"
    File html_report = "~{sample_name}.qualimap_bamqc/qualimapReport.html"
    File pdf_report = "~{sample_name}.qualimap_bamqc/qualimapReport.pdf"
    File genome_results = "~{sample_name}.qualimap_bamqc/genome_results.txt"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }
}
