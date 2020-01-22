#! /opt/hpc/bin/bash
IMGDIR="$1"
IMGFILE="$2"
KDU_DIR=/sonas-hs/mitra/hpc/home/kram/kakadu/kdu71
WORKDIR=/sonas-hs/mitra/hpc/home/kram/Compute

echo "thumbnail"

LD_LIBRARY_PATH=${KDU_DIR} ${KDU_DIR}/kdu_expand -i "$IMGDIR/${IMGFILE}.jp2" -o "${IMGDIR}/${IMGFILE}.tif" -reduce 6 -num_threads 16

convert "${IMGDIR}/${IMGFILE}.tif" -depth 8 "${IMGDIR}/${IMGFILE}.jpg"

