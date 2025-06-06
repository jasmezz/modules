process GANGSTR {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gangstr:2.5.0--h48cf4b7_4':
        'biocontainers/gangstr:2.5.0--h48cf4b7_4' }"

    input:
    tuple val(meta), path(alignment_files), path(alignment_indices), path(ref_regions)
    path(fasta)
    path(fasta_fai)

    output:
    tuple val(meta), path("*.vcf.gz")           , emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi")       , emit: index
    tuple val(meta), path("*.samplestats.tab")  , emit: samplestats
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def input = alignment_files.join(",")

    """
    GangSTR \\
        --bam ${input} \\
        --ref ${fasta} \\
        --regions ${ref_regions} \\
        --out ${prefix} \\
        ${args}

    bgzip -f ${prefix}.vcf
    tabix -f -p vcf ${prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gangstr: \$(echo \$(GangSTR --version 2>&1))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo | gzip > ${prefix}.vcf.gz
    touch ${prefix}.vcf.gz.tbi
    touch ${prefix}.samplestats.tab

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gangstr: \$(echo \$(GangSTR --version 2>&1))
    END_VERSIONS
    """
}
