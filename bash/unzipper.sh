#!/bin/bash

#########################################
# options de débuggage
set -euo pipefail # -x activer pour plus de debug

# options de glob étendu
shopt -s extglob

#########################################
# Script de Préparation de grands GeoTIFF  
# Pour le déployemnt de MapServer / MapCache
# Khaldoune Hilami. 12/06/2026
# @: khilami@bouyguestelecom.fr 
#########################################
# Usage:
# ./prep_rast.sh
#
# Example:
# ./prep_rast.sh
#########################################

# variables et configuration I/O:
WORKDIR=$(pwd)
SRS_OUT=3857
REGION='idf'
BASENAME=$REGION
TILE_INDEX="${BASENAME}.shp"
INPUT_VRT="${BASENAME}.vrt"
REPROJECTED="${BASENAME}_${SRS_OUT}.tif"
TILED="${BASENAME}_${SRS_OUT}_tiled.tif"
COG_OUTPUT="${BASENAME}_${SRS_OUT}_cog.tif"
MAIN_SPLIT=01

# variables de controle de flux:
DEPTS=(75 77 78 91 92 93 94 95)
ZOOM_LEVELS=($(printf " %02d" {8..19}))

# configuration GDAL
RESAMPLE_ALGO=bilinear
COMPRESS_ALGO=ZSTD
COMPRESS_LEVEL=9
N_PROC=$(nproc)
BLOCKSIZE=512
PREDICTOR=2

# création d'un répertoir par région:
# désarchiver la donnée raster IGN
for DEP in ${DEPTS[@]}
do
	DEPARTEMENT=$(printf "%02d" $DEP)
	DEPARTEMENT=DEPARTEMENT_${DEP}
	for ZOOM_LEVEL in ${ZOOM_LEVELS[@]}
	do
		ZOOM_FOLDER=ZOOM_$ZOOM_LEVEL
		mkdir -p ./$REGION/$DEPARTEMENT/$ZOOM_FOLDER
		zip=PLANIGN_1-0__TIFF_LAMB93_D0${DEP}_2025-12-01.7z.0${MAIN_SPLIT}

		if [[ -e $zip && -x $zip && -r $zip ]]
		then
			7zz -y -r e $zip -o./$REGION/$DEPARTEMENT/$ZOOM_FOLDER PLANIGN${ZOOM_LEVEL}_*_L93.tif;
		else
			echo "Zip not found in WORKDIR: $WORKDIR"
		fi
	done;
done;


