#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

params.ome_tiffs = "/nfs/team283_imaging/AC_LNG/0_CARTANA_ISS_I2B-panel/OB01011_FF_Lung_CARTANA_I2B_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"
/*params.ome_tiffs = "/nfs/team283_imaging/0HarmonyStitched/JSP_HSS/playground_Jun/OB10036_FF_Brain_CARTANA_N1C_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"*/
/*params.ome_tiffs = "/nfs/team283_imaging/0HarmonyStitched/JSP_HSS/playground_Jun/OB10037_FF_Brain_CARTANA_N1234F_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"*/
params.out_dir = "./out_lung"
params.skip_raw_pyramid = true


process fake_anchor_chs {
    echo true
    container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/fake_anchor.sif"
    /*container "/nfs/team283_imaging/0Misc/ImageAnalysisTools/img-bftools.sif"*/
    storeDir params.out_dir


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
    storeDir params.out_dir

    input:
    file tif from tif_with_anchor

    output:
    file "*registered.tif" into opt_registered

    script:
    """
    python3 /home/ubuntu/Documents/opt_flow_reg/opt_flow_reg.py -i "${tif}" -c "anchor" -o ./ -n 14
    """
}

process convert_to_zarr {
    /*echo true*/
    container "gitlab-registry.internal.sanger.ac.uk/tl10/img-bftools"
    /*container "gitlab-registry.internal.sanger.ac.uk/olatarkowska/img-bioformats2raw:0.3.0"*/
    /*storeDir params.out_dir + "/raws"*/
    /*publishDir params.out_dir + "/tmp", mode:"copy"*/

    input:
    file img from opt_registered

    output:
    tuple val(stem), file("${stem}") into raws

    script:
    stem = img.baseName
    """
    #/opt/bioformats2raw/bin/bioformats2raw --max_workers 15 --resolutions 7 --tile_width 512 --tile_height 512 $img "${stem}.zarr"
    /bf2raw/bioformats2raw-0.2.6/bin/bioformats2raw --dimension-order XYZCT --max_workers 15 --resolutions 7 --tile_width 512 --tile_height 512 $img "${stem}"
    """
}


process zarr_to_ome_tiff {
    /*echo true*/
    container "gitlab-registry.internal.sanger.ac.uk/tl10/img-bftools"
    /*container "gitlab-registry.internal.sanger.ac.uk/olatarkowska/img-raw2ometiff:0.1.1"*/
    storeDir params.out_dir + "/ome_tiffs"

    input:
    tuple val(stem), file(zarr) from raws

    output:
    tuple val(stem), path("${stem}.ome.tif") into ome_tiffs

    script:
    """
    export _JAVA_OPTIONS="-Xmx128g"
    #/opt/raw2ometiff-0.1.1-SNAPSHOT/bin/raw2ometiff --max_workers 12 --debug "${zarr}" "${stem}.ome.tif"
    /raw2tif/raw2ometiff-0.2.8/bin/raw2ometiff --max_workers 12 --debug "${zarr}" "${stem}.ome.tif"
    """
}
