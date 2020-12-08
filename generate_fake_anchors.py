#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2020 Tong LI <tongli.bioinfo@protonmail.com>
#
# Distributed under terms of the BSD-3 license.

"""
Take ome.tif as input and generate fake anchors channels for decoding cycles
"""
import argparse


def main(args):
    print(args._in)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("-_in", type=str,
            required=True)

    args = parser.parse_args()

    main(args)
