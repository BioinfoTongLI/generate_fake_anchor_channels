#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

/*params.ome_tiffs = "/nfs/team283_imaging/AC_LNG/0_CARTANA_ISS_I2B-panel/OB01011_FF_Lung_CARTANA_I2B_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"*/
params.ome_tiffs = "/nfs/team283_imaging/0HarmonyStitched/JSP_HSS/playground_Jun/OB10036_FF_Brain_CARTANA_N1C_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"
params.out_dir = "./out"
params.skip_raw_pyramid = true

process fake_anchor_chs {
    echo true
    container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/fake_anchor.sif"
    /*container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/img-bftools.sif"*/

    input:
    file ome_tif from channel.fromPath(params.ome_tiffs)

    output:
    file "*anchors.ome.tif" into tif_with_anchor, tif_with_anchor_for_pyramid

    script:
    """
    python3 ${baseDir}/generate_fake_anchors.py -ome_tif ${ome_tif} -known_anchor "c01 Alexa 647"
    """
}

process build_pyramid_raw {
    container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/img-bftools.sif"
    publishDir params.out_dir, mode:"copy"

    when:
    !params.skip_raw_pyramid

    input:
    file tif from tif_with_anchor_for_pyramid

    output:
    tuple val(stem), file("${stem}*pyramid*.ome.tif")

    script:
    stem = tif.baseName
    """
    export _JAVA_OPTIONS="-Xmx128g"
    /bftools/bftools/bfconvert -pyramid-resolutions 5 -pyramid-scale 2 ${tif} ${stem}_pyramid_5.ome.tif
    """
}

process opt_flow_register {
    echo true
    container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/opt-reg.sif"
    /*publishDir params.out_dir, mode:"copy"*/

    input:
    file tif from tif_with_anchor

    output:
    file "*registered.tif" into opt_registered

    script:
    """
    python3 /home/ubuntu/Documents/opt_flow_reg/opt_flow_reg.py -i "${tif}" -c "anchor" -o ./ -n 14
    """
}

process build_pyramid {
    container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/img-bftools.sif"
    publishDir params.out_dir, mode:"copy"

    input:
    file tif from opt_registered

    output:
    tuple val(stem), file("${stem}*pyramid*.ome.tif")

    script:
    stem = tif.baseName
    """
    export _JAVA_OPTIONS="-Xmx128g"
    /bftools/bftools/bfconvert -pyramid-resolutions 5 -pyramid-scale 2 ${tif} ${stem}_pyramid_5.ome.tif
    """
}
