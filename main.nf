#!/usr/bin/env/ nextflow

// Copyright (C) 2020 Tong LI <tongli.bioinfo@protonmail.com>

params.ome_tiffs = "/nfs/team283_imaging/AC_LNG/0_CARTANA_ISS_I2B-panel/OB01011_FF_Lung_CARTANA_I2B_Cycles0123456_x20/feature_based_reg_DAPI/out.tif"

process fake_anchor_chs {
    echo true

    input:
    file ome_tif from channel.fromPath(params.ome_tiffs)

    //output:

    script:
    """
    echo ${ome_tif}
    echo ${baseDir}
    """
}

