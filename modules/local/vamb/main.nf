process VAMB {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'vamb_02a9a6e':
        'biocontainers/vamb:4.1.3--py311h7b50bb2_0' }"

    input:
    tuple val(meta), path(contigs), path(depth), path(tax)

    output:
    tuple val(meta), path("vae_clusters_unsplit.tsv"), emit: clusters_unsplit_tsv
    tuple val(meta), path({"${prefix}_bins"}), emit: bin_fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    zcat $depth | tail -n+2 | cut -f1,3 > ${prefix}_depth.tsv
    vamb bin taxvamb \\
        -p $task.cpus \\
        $args \\
        --outdir $prefix \\
        --fasta $contigs \\
        --abundance_tsv ${prefix}_depth.tsv \\
        --taxonomy $tax \\
        -m 100


    create_fasta.py \\
        $contigs \\
        ${prefix}/vae_clusters_unsplit.tsv \\
        200 \\
        ${prefix}_bins


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vamb: \$(vamb --version |& sed '1!d ; s/Vamb //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    touch ${prefix}/vae_clusters_unsplit.tsv
    mkdir ${prefix}_bins

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vamb: \$(vamb --version |& sed '1!d ; s/Vamb //')
    END_VERSIONS
    """
}
