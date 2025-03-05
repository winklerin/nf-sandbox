process MMSEQS2KRAKEN {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mmseqs2:15.6f452--pl5321h6a68c12_0':
        'biocontainers/mmseqs2:15.6f452--pl5321h6a68c12_0' }"

    input:
    tuple val(meta), path(db_contig)
    tuple val(meta2), path(db_taxonomy)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: "*.dbtype" //represents the db_query
    def args3 = task.ext.args3 ?: "*.dbtype" //represents the db_target
    prefix = task.ext.prefix ?: "${meta.id}"

    """

    # Extract files with specified args based suffix | remove suffix | isolate longest common substring of files
    SEQTAXDB=\$(find -L "${db_contig}/" -maxdepth 1 -name "${args2}" | sed 's/\\.[^.]*\$//' | sed -e 'N;s/^\\(.*\\).*\\n\\1.*\$/\\1\\n\\1/;D' )
    TAXONOMY_RESULT=\$(find -L "${db_taxonomy}/" -maxdepth 1 -name "${args3}" | sed 's/\\.[^.]*\$//' | sed -e 'N;s/^\\(.*\\).*\\n\\1.*\$/\\1\\n\\1/;D' )

    mmseqs \\
        taxonomyreport \\
        \$SEQTAXDB \\
        \$TAXONOMY_RESULT \\
        ${prefix}_kraken.tsv \\
        $args 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mmseqs: \$(mmseqs | grep 'Version' | sed 's/MMseqs2 Version: //')
    END_VERSIONS
    """
}
