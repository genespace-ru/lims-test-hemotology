version 1.0

task MosdepthByTargets {

  input {

    File bam
    File bai
    File targets_bed
    String sample_name
    String thresholds = "10,20,50,100,250"

    Int threads = 4
    Int ram_g = 4
    String docker_image = "quay.io/biocontainers/mosdepth:0.3.14--h05c3d44_0"

  }

  command <<<

    mkdir mosdepth

    BAM=$(basename ~{bam})

    ln -s ~{bam} $BAM
    ln -s ~{bai} $BAM.bai

    mosdepth \
      --thresholds ~{thresholds} \
      --threads ~{threads} \
      --by ~{targets_bed} \
      mosdepth/~{sample_name}.mosdepth \
      $BAM

    mv mosdepth/~{sample_name}.mosdepth.mosdepth.summary.txt mosdepth/~{sample_name}.mosdepth.summary.txt
    mv mosdepth/~{sample_name}.mosdepth.mosdepth.global.dist.txt mosdepth/~{sample_name}.mosdepth.global.dist.txt
    mv mosdepth/~{sample_name}.mosdepth.mosdepth.region.dist.txt mosdepth/~{sample_name}.mosdepth.region.dist.txt

  >>>

  output {

    File summary = "mosdepth/~{sample_name}.mosdepth.summary.txt"

    File regions_bed_gz = "mosdepth/~{sample_name}.mosdepth.regions.bed.gz"
    File regions_bed_gz_csi = "mosdepth/~{sample_name}.mosdepth.regions.bed.gz.csi"

    File thresholds_bed_gz = "mosdepth/~{sample_name}.mosdepth.thresholds.bed.gz"
    File thresholds_bed_gz_csi = "mosdepth/~{sample_name}.mosdepth.thresholds.bed.gz.csi"

    File per_base_bed_gz = "mosdepth/~{sample_name}.mosdepth.per-base.bed.gz"
    File per_base_bed_gz_csi = "mosdepth/~{sample_name}.mosdepth.per-base.bed.gz.csi"

    File global_dist = "mosdepth/~{sample_name}.mosdepth.global.dist.txt"
    File region_dist = "mosdepth/~{sample_name}.mosdepth.region.dist.txt"

  }

  runtime {

    docker: docker_image
    cpu: threads
    memory: "~{ram_g}G"

  }

}

