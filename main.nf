#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-mmseqs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/luwinklerchen/nf-mmseqs
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2


include { validateParameters; paramsSummaryLog; fromSamplesheet } from 'plugin/nf-validation'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES AND SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INITIALISE } from './subworkflows/local/initialise'
include { MMSEQS_CONTIG_TAXONOMY } from './subworkflows/nf-core/mmseqs_contig_taxonomy/main'
include { VAMB } from './modules/local/vamb/main'
include { TAXCONVERTER } from './modules/local/taxconverter/main'
include { GUNZIP } from './modules/nf-core/gunzip/main'

// Print parameter summary log to screen before running
log.info paramsSummaryLog(workflow)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NFMMSEQS {

    ch_versions = Channel.empty()

    INITIALISE()

    // Parse samplesheet (format: sample;contig_fasta;depth)
// Read and parse the sample sheet
 Channel
    .fromPath(params.input)   // Path to your CSV file
    .splitCsv(header: true)   // Splits the CSV into columns (if it has a header)
    .map { row ->
        [[id: row.sample], file(row.contig_fasta), file(row.depth)]
    }
    .view()
    .set{samplesheet_channel}


// Channel for process requiring sample and contig_fasta
samplesheet_channel.map { meta, contigs, depth -> [meta, contigs] }
    .set { contigChannel }

// Channel for process requiring sample and depth
samplesheet_channel.map { meta, contigs, depth -> [meta, depth] }
    .set { depthChannel }

    // Run MMseqs Taxonomy on contigs
    MMSEQS_CONTIG_TAXONOMY(
       contigChannel,
       params.db,
       []
    )

    TAXCONVERTER(MMSEQS_CONTIG_TAXONOMY.out.taxonomy)


    //Expected input: tuple val(meta), path(contigs), path(depth), path(tax)
    VAMB(contigChannel
            .join(
                depthChannel
            ).join(
                TAXCONVERTER.out.tsv
            )
        )
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow {
    NFMMSEQS ()
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PARAMETERS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
