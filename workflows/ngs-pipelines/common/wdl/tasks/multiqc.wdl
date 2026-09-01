version 1.0

task MultiQC {

  input {
    Array[File] qc_files
    String output_prefix
    Int ram_g = 4
    String docker_image = "multiqc/multiqc:v1.29"
  }

  command <<<

    mkdir -p multiqc_input
    mkdir multiqc

    i=0
    for file in ~{sep=' ' qc_files}; do
      mkdir -p multiqc_input/file_${i}
      ln -s "$file" "multiqc_input/file_${i}/$(basename "$file")"
      i=$((i + 1))
    done

    multiqc \
      multiqc_input \
      --outdir multiqc \
      --filename ~{output_prefix}.multiqc.html \
      --force \
      --data-format json

  >>>

  output {
    File html_report = "multiqc/~{output_prefix}.multiqc.html"
    File json_data = "multiqc/~{output_prefix}.multiqc_data/multiqc_data.json"
    File sources = "multiqc/~{output_prefix}.multiqc_data/multiqc_sources.json"
    Array[File] data_files = glob("multiqc/~{output_prefix}.multiqc_data/*")
  }

  runtime {
    docker: docker_image
    memory: "~{ram_g}G"
  }
}
