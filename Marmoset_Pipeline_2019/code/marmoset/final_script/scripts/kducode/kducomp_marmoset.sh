#! /opt/hpc/bin/bash

IMGFILE=$1
OUTDIR=$2
OUTNAME="$3"
KDU_DIR=/sonas-hs/mitra/hpc/home/kram/kakadu/kdu71
WORKDIR=/sonas-hs/mitra/hpc/home/kram/Compute

echo "compress"

LD_LIBRARY_PATH=${KDU_DIR} ${KDU_DIR}/kdu_compress -i $IMGFILE -o "${OUTDIR}/${OUTNAME}.jp2" -rate 1 Qstep=0.00001 Clevels=20 Clayers=8 ORGgen_plt=yes ORGtparts=R "Cblk={32,32}" -num_threads 1 #&& rm -f $WORKDIR/outputs/transformedtifs/${IMGNO}_${STYPE}_${SLICENO}.tif
#-rate 1 Qstep=0.00001 Clevels=5 Clayers=5 ORGgen_plt=yes ORGtparts=R "Cblk={64,64}"

