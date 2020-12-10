#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

params.ome_tiffs = "/nfs/team283_imaging/AC_LNG/0_CARTANA_ISS_I2B-panel/OB01011_FF_Lung_CARTANA_I2B_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"

process fake_anchor_chs {
    echo true
    /*publishDir "./", mode:"copy"*/
    container "./env.sif"

    input:
    file ome_tif from channel.fromPath(params.ome_tiffs)

    output:
    file "*anchors.ome.tif" into tif_with_anchor

    script:
    """
    python3 ${baseDir}/generate_fake_anchors.py -ome_tif ${ome_tif} -known_anchor "c01 Alexa 647"
    """
}

process tif_2_raw {

    input:
    file tif from tif_with_anchor

    output:
    tuple val(stem), file("${stem}*pyramid*.ome.tif") into zarrs

    script:
    stem = tif.baseName
    """
    bfconvert -pyramid-resolutions 5 -pyramid-scale 2 /nfs/team283_imaging/JSP_HSS/playground_Tong/gmm_decoding_nf_out/out_with_anchors.ome.tif /nfs/team283_imaging/JSP_HSS/playground_Tong/gmm_decoding_nf_out/out_with_anchors_pyramid_5.ome.tif
    """
}
