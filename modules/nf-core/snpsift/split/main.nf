process SNPSIFT_SPLIT {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/snpsift:4.3.1t--hdfd78af_3' :
        'biocontainers/snpsift:4.3.1t--hdfd78af_3' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.vcf"), emit: out_vcfs
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if (meta.split) {
        """
        SnpSift \\
            split \\
            $args \\
            $vcf

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            snpsift: \$( echo \$(SnpSift split -h 2>&1) | sed 's/^.*version //' | sed 's/(.*//' | sed 's/t//g' )
        END_VERSIONS
        """
    } else {
        """
        SnpSift \\
            split \\
            -j \\
            $args \\
            $vcf \\
            > ${prefix}.joined.vcf

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            snpsift: \$( echo \$(SnpSift split -h 2>&1) | sed 's/^.*version //' | sed 's/(.*//' | sed 's/t//g' )
        END_VERSIONS
        """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.chr1.vcf
    touch ${prefix}.chr2.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        snpsift: \$( echo \$(SnpSift split -h 2>&1) | sed 's/^.*version //' | sed 's/(.*//' | sed 's/t//g' )
    END_VERSIONS
    """
}
