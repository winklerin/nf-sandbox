process FILTER_CONTIGS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/pip_pandas_pysam:f526fc25eda2567e':
        '' }"

    input:
    tuple val(meta), path(fasta), path(depth), path(taxonomy)

    output:

    tuple val(meta), path("*.length_filtered.fa"), path("*.depth_filtered.tsv"), path("*.taxonomy_filtered.tsv"), emit: filtered

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e "contigname\tcoverage" > ${prefix}_depth.tsv
    zcat $depth | tail -n+2 | cut -f1,3 >> ${prefix}_depth.tsv

    filter_contigs.py \\
        $fasta \\
        -t $taxonomy \\
        -d ${prefix}_depth.tsv \\
        -b $prefix \\
        $args
    """
}
