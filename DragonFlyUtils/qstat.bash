#!/bin/bash

export SGE_ROOT="/opt/gridengine"
export SGE_CELL="scalable"
export SGE_ARCH="lx24-amd64"

$SGE_ROOT/bin/$SGE_ARCH/qstat $*
