#!/bin/bash

#########################################
# options de debuggage
set -euo pipefail # -x activer pour plus de debug

# options de glob etendu
shopt -s extglob

###########################################
# Script de Preparation de grands GeoTIFF
# Pour le deployement de MapServer/MapCache
# Khaldoune Hilami. 12/06/2026
# @: email@here.com
###########################################
# Usage:
# ./prep_rast.sh
#
# Example:
# ./prep_rast.sh
###########################################

# variables et configuration I/O:
WORKDIR=$(pwd)
SRS_OUT=3857
DATA_DIR='IGN_DATA'
RASTER_DIR='IGN_REGIONS'
REGION='IDF'
INDEX_DIR="${RASTER_DIR}/${REGION}/${REGION}_TILEINDEX"
BASENAME=$REGION
INPUT_VRT="${INDEX_DIR}/${BASENAME}.vrt"
MAIN_SPLIT=01

# variables de controle de flux:
#DEPTS=(75 77 78 91 92 93 94 95)
DEPTS=(75)
ZOOM_LEVELS=($(printf " %02d" {8..19}))

# reproject the index:
INDEX="${INDEX_DIR}/staged_idf.shp"
INDEX_buffered="${INDEX_DIR}/staged_idf_buffered.shp"
INDEX_3857="${INDEX_DIR}/staged_idf_3857.shp"
TILEINDEX="${INDEX_DIR}/${REGION}_TILEINDEX.shp"
BUFFER=50


# configuration GDAL
RESAMPLE_ALGO=cubic
COMPRESS_ALGO=DEFLATE
COMPRESS_LEVEL=7
PREDICTOR=2
N_PROC=$(nproc)
BLOCKSIZE=512
WARP_MEMORY=1024
JOBS=20

export RESAMPLE_ALGO COMPRESS_ALGO COMPRESS_LEVEL INDEX_DIR
export PREDICTOR BLOCKSIZE WARP_MEMORY N_PROC JOBS


###################################### functions ############################################

function download_zip(){
    # telechargement des archives IGN
	SPLITS=$(printf "%02d" {1..10})
	for SPLIT in ${SPLITS[@]}
	do
		DEPARTEMENT=$(printf "%02d" $DEP)
		
	done;

}

# fonction de creation d'un repertoir par region:
# desarchiver la donnee raster IGN
function unzip_rasters(){
	# desarchiver les rasters IGN:
	for DEP in ${DEPTS[@]}
	do
		DEPARTEMENT=$(printf "%02d" $DEP)
		DEPARTEMENT=DEPARTEMENT_${DEP}
		for ZOOM_LEVEL in ${ZOOM_LEVELS[@]}
		do
			ZOOM_FOLDER=ZOOM_$ZOOM_LEVEL
			mkdir -p ./$RASTER_DIR/$REGION/$DEPARTEMENT/$ZOOM_FOLDER
			zip=./$DATA_DIR/$REGION/PLANIGN_1-0__TIFF_LAMB93_D0${DEP}_2025-12-01.7z.0${MAIN_SPLIT}

			if [[ -e $zip && -x $zip && -r $zip ]]
			then
				7zz -y -r e $zip -o./$RASTER_DIR/$REGION/$DEPARTEMENT/$ZOOM_FOLDER PLANIGN${ZOOM_LEVEL}_*_L93.tif;
			else
				echo "Zip not found in WORKDIR: IGN_DATA/$REGION"
			fi
		done;
	done;
}


function webmercator_tiled(){
	
	INPUT_LAYER=$1
	BASENAME=$(basename $1 .tif)
	DIRNAME=$(dirname $1)
	REPROJECTED_BUFFERD="${DIRNAME}/${BASENAME}_web_buffer.tif"
	REPROJECTED_CROPPED="${DIRNAME}/${BASENAME}_web.tif"
	INDEX_BUFFER=$2
	INDEX_CROP=$3
	VRT=$4
	CLIPPER="${INDEX_DIR}/clipper_${BASENAME}.geojson"

	REGION=$(echo ${INPUT_LAYER} | cut -d/ -f 8)
	DEPARTEMENT=$(echo ${INPUT_LAYER} | cut -d/ -f 9)
	ZOOM_LEVEL=$(echo ${INPUT_LAYER} | cut -d/ -f 10)
	RASTER=$(echo ${INPUT_LAYER} | cut -d/ -f 11)

	echo -e "\nRegion: ${REGION}"
	echo "Departement: ${DEPARTEMENT}"
	echo "Zoom level: ${ZOOM_LEVEL}"
	echo "processing buffer zone for file: TIFF ${RASTER}"

	gdalwarp \
	  --config GDAL_CACHEMAX $WARP_MEMORY \
	  -wm $WARP_MEMORY \
	  -tr 0.298582141739 0.298582141739 \
	  -tap \
	  -r $RESAMPLE_ALGO \
	  -s_srs EPSG:2154 \
	  -t_srs EPSG:3857 \
	  -cutline $INDEX_BUFFER \
	  -crop_to_cutline \
	  -cwhere "location = '${INPUT_LAYER}'" \
	  -wo SOURCE_EXTRA=64 \
	  -wo NUM_THREADS=$N_PROC \
	  -multi \
	  -co NUM_THREADS=$N_PROC \
	  -co BIGTIFF=YES \
	  -overwrite \
	  $VRT \
	  $REPROJECTED_BUFFERD;

	echo -e "cropping back to file extent: TIFF ${BASENAME}"

	if [[ -f $CLIPPER ]]
	then
		rm -rf $CLIPPER;
	fi

	ogr2ogr \
		-t_srs EPSG:3857 \
		-of 'GeoJSON' \
		$CLIPPER \
		$INDEX_CROP \
		-where "location='${INPUT_LAYER}'" \
		-nln 'clipper'

	Xmin=$(ogrinfo $CLIPPER clipper -json | jq -r '.layers[0].geometryFields[0].extent[0]');
	Ymax=$(ogrinfo $CLIPPER clipper -json | jq -r '.layers[0].geometryFields[0].extent[3]');
	Xmax=$(ogrinfo $CLIPPER clipper -json | jq -r '.layers[0].geometryFields[0].extent[2]');
	Ymin=$(ogrinfo $CLIPPER clipper -json | jq -r '.layers[0].geometryFields[0].extent[1]');

	gdal_translate \
	  -projwin $Xmin $Ymax $Xmax $Ymin \
	  -projwin_srs EPSG:3857 \
	  -co COMPRESS=$COMPRESS_ALGO \
	  -co PREDICTOR=$PREDICTOR \
	  -co ZLEVEL=$COMPRESS_LEVEL \
	  -co TILED=YES \
	  -co BLOCKXSIZE=$BLOCKSIZE \
	  -co BLOCKYSIZE=$BLOCKSIZE \
	  -co BIGTIFF=YES \
	  -co NUM_THREADS=$N_PROC \
	  $REPROJECTED_BUFFERD \
	  $REPROJECTED_CROPPED;

    # cleanup
	if [[ -f $REPROJECTED_BUFFERD ]]
	then
		rm -rf $REPROJECTED_BUFFERD;
	fi

	if [[ -f $CLIPPER ]]
	then
		rm -rf $CLIPPER;
	fi
}

###################################### MAIN JOB ############################################

# creation d'un repertoir par region:
# desarchiver la donnee raster IGN
if [[ ! -d $REGION ]]
then
	unzip_rasters;
fi

# List all region tifs:
# indexed array to host tif names:
typeset -a IDFTIFS
typeset -a IDFTIFSWEB

#PATTERN="PLANIGN${ZOOM_LEVEL}_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]_L93.tif"
PATTERN="PLANIGN19_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]_L93.tif"

for dep in ${DEPTS[@]}
do
	DEPARTEMENT=$(printf "%02d" $dep)
	DEPARTEMENT=DEPARTEMENT_${DEPARTEMENT}
	SUBFOLDER_0=$RASTER_DIR
	SUBFOLDER_1=$REGION
	SUBFOLDER_2=$DEPARTEMENT
	SUBFOLDER_3='ZOOM_19'
	deptpath=$PWD/$SUBFOLDER_0/$SUBFOLDER_1/$SUBFOLDER_2/$SUBFOLDER_3
	IDFTIFS+=($deptpath/$PATTERN)
done;

# build a tile index for buffered warping/reprojection:
gdaltindex \
	-t_srs EPSG:2154 \
	-write_absolute_path \
	-overwrite \
	-src_srs_name src_srs \
	$INDEX \
	$(echo ${IDFTIFS[@]})

# create buffered version
ogr2ogr \
  $INDEX_buffered \
  $INDEX \
  -dialect SQLITE \
  -sql "SELECT ST_Buffer(geometry, ${BUFFER}) AS geometry, * FROM $(basename $INDEX .shp)"

# reproject the index into 3857
ogr2ogr \
	-s_srs EPSG:2154 \
	-t_srs EPSG:3857 \
	-of 'ESRI Shapefile' \
	$INDEX_3857 \
	$INDEX

echo -e '\nCreating Virtual Mosaic for all involved rasters.'
# build a coherent virtual layer
gdalbuildvrt -resolution highest $INPUT_VRT $(echo ${IDFTIFS[@]})

echo -e '\nCreating Reprojected GeoTIFF Raster from input ...'

#for tif in ${IDFTIFS[@]}
#do
#	webmercator_tiled $tif $INDEX_buffered $INDEX_3857 $INPUT_VRT
#done;

export -f webmercator_tiled

parallel -j $JOBS \
 "webmercator_tiled {1} ${INDEX_buffered} ${INDEX_3857} ${INPUT_VRT}" \
 ::: $(echo ${IDFTIFS[@]});

#PATTERN="PLANIGN${ZOOM_LEVEL}_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]_L93.tif"
PATTERN="PLANIGN19_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]_L93.tif"

for dep in ${DEPTS[@]}
do
	DEPARTEMENT=$(printf "%02d" $dep)
	DEPARTEMENT=DEPARTEMENT_${DEPARTEMENT}
	SUBFOLDER_0=$RASTER_DIR
	SUBFOLDER_1=$REGION
	SUBFOLDER_2=$DEPARTEMENT
	SUBFOLDER_3='ZOOM_19'
	deptpath=$PWD/$SUBFOLDER_0/$SUBFOLDER_1/$SUBFOLDER_2/$SUBFOLDER_3
	IDFTIFSWEB+=($deptpath/$PATTERN)
done;

echo 'Raster creation complete.'


echo 'Creating tile index of staged rasters'

# build a tile index:
gdaltindex \
	-t_srs EPSG:3857 \
	-write_absolute_path \
	-overwrite \
	-src_srs_name src_srs \
	$TILEINDEX \
	$(echo ${IDFTIFSWEB[@]})

echo 'Adding index tree to tile index ...'
shptree $TILEINDEX
echo 'Adding index tree complete.'

tree $RASTER_DIR/$REGION > "${INDEX_DIR}/${REGION}_tree.txt"

chmod -R 775 **

echo 'Creating tile index complete.';
