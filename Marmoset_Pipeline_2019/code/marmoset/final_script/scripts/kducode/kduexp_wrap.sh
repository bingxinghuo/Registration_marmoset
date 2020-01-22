#! /opt/hpc/bin/bash
IMGDIR="$1"
IMGFILE="$2"
OUTDIR=$3
OUTNAME=$4
KDU_DIR=/sonas-hs/mitra/hpc/home/kram/kakadu/kdu71
WORKDIR=/sonas-hs/mitra/hpc/home/kram/Compute

mkdir -p $OUTDIR
echo "expand"

LD_LIBRARY_PATH=${KDU_DIR} ${KDU_DIR}/kdu_expand -i "$IMGDIR/${IMGFILE}_lossless.jp2" -o ${OUTDIR}/${OUTNAME} -resilient -num_threads 16 

