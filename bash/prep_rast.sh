#!/bin/bash

#########################################
# options de debuggage
set -e -u -o pipefail

#activer pour plus de debug
#set -x

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
N_PROC=$(nproc)
SRS_IN=2154
SRS_OUT=3857
DATA_DIR='IGN_DATA'
RASTER_DIR='IGN_REGIONS'


###################################### functions ############################################

function download_zip(){
	
	# telechargement des archives IGN
	DEP=$1
	SPLITS=({01..10})
	BASE_URL='https://data.geopf.fr/telechargement/download/PLANIGN'

	if [[ ! -d $DATA_DIR/$REGION ]]
	then
		mkdir -p $DATA_DIR/$REGION;
	fi

	#format the department code:
	DEP=$(printf "%02d" "$DEP")
	for SPLIT in "${SPLITS[@]}"
	do
		#format the split rank
		FILE_FOLDER="PLANIGN_1-0__TIFF_LAMB93_D0${DEP}_2025-12-01"
		FILE_NAME="PLANIGN_1-0__TIFF_LAMB93_D0${DEP}_2025-12-01.7z.0${SPLIT}"
		TARGET="$BASE_URL/$FILE_FOLDER/$FILE_NAME"
		# sanity check
		if [[ ! -f $DATA_DIR/$REGION/$FILE_NAME ]]
		then
			if wget --spider "$TARGET" --quiet
			then
				#download of the 7zip fragment
				wget --no-clobber --no-check-certificate "$TARGET" \
					-O $DATA_DIR/$REGION/"$FILE_NAME" #2>&1 /dev/null
				chmod 775 $DATA_DIR/$REGION/"$FILE_NAME"
				echo -e "\n zip downloaded for 7z split ${SPLIT}\n"
			else
				echo ' Rest of splits out of range'
				break
			fi
		else
			echo ' Archive split exists. skip...'
		fi
	done;
}


# fonction de creation d'un repertoir par region:
# desarchiver la donnee raster IGN
function unzip_rasters(){
	
	ACTIVATE_DOWNLOAD=$1
	MAIN_SPLIT=01

	#telecharger puis desarchiver les rasters IGN du department:
	for DEP in "${DEPTS[@]}"
	do
		#download target department data zip:
		if [[ $ACTIVATE_DOWNLOAD == 'ZIP_DL' ]]
                then
			download_zip "$DEP"
                else
			echo "\n Download not requested for Departement ${DEP} ... Skipping\n"
                fi

		#extract raster data from zip:
		DEPARTEMENT=$(printf "%02d" "$DEP")
		DEPARTEMENT=DEPARTEMENT_${DEPARTEMENT}
		for ZOOM_LEVEL in "${ZOOM_LEVELS[@]}"
		do
			ZOOM_FOLDER=ZOOM_$ZOOM_LEVEL
			mkdir -p ./$RASTER_DIR/$REGION/"$DEPARTEMENT"/"$ZOOM_FOLDER"
			zip="$DATA_DIR/$REGION/PLANIGN_1-0__TIFF_LAMB93_D0${DEP}_2025-12-01.7z.0${MAIN_SPLIT}"
			TIF_FILTER="PLANIGN${ZOOM_LEVEL}_*_L93.tif"
			echo -e "\n Extracting ${ZOOM_FOLDER} for $DEPARTEMENT ..."

			if [[ -e $zip && -r $zip ]]
			then
				7zz -bso0 -bse1 -bsp2 -mmt="$N_PROC" -y -r e "$zip" \
					 -o./$RASTER_DIR/$REGION/"$DEPARTEMENT"/"$ZOOM_FOLDER" "$TIF_FILTER";
			else
				echo "Zip not found in WORKDIR: ${DATA_DIR}/${REGION}"
			fi
		done;

		echo -e "\n ******************************\n"
	done;
}


# this function takes in a zoom level and returns
# the pixel resolution in meters per pixel m/px in
# Web Mercator EPSG 3857
function zoom_resolver(){

	#input zoom level to resolve
	ZOOM=$1

	# Piking the right resolution for SRS_OUT:
	case $ZOOM in
	08) ZOOM_RESOLUTION=611.49622628141
		echo $ZOOM_RESOLUTION
		;;
	09) ZOOM_RESOLUTION=305.748113140705
		echo $ZOOM_RESOLUTION
		;;
	10) ZOOM_RESOLUTION=152.8740565703525
		echo $ZOOM_RESOLUTION
		;;
	11) ZOOM_RESOLUTION=76.43702828517625
		echo $ZOOM_RESOLUTION
		;;
	12) ZOOM_RESOLUTION=38.21851414258813
		echo $ZOOM_RESOLUTION
		;;
	13) ZOOM_RESOLUTION=19.109257071294063
		echo $ZOOM_RESOLUTION
		;;
	14) ZOOM_RESOLUTION=9.554628535647032
		echo $ZOOM_RESOLUTION
		;;
	15) ZOOM_RESOLUTION=4.777314267823516
		echo $ZOOM_RESOLUTION
		;;
	16) ZOOM_RESOLUTION=2.388657133911758
		echo $ZOOM_RESOLUTION
		;;
	17) ZOOM_RESOLUTION=1.194328566955879
		echo $ZOOM_RESOLUTION
		;;
	18) ZOOM_RESOLUTION=0.5971642834779395
		echo $ZOOM_RESOLUTION
		;;
	19) ZOOM_RESOLUTION=0.29858214173896974
		echo $ZOOM_RESOLUTION
		;;
	esac
}


# creates a reprojected mosaic from a vrt
function tile_merger(){

	#virtual layer to reproject and mosaic:
	VRT=$1
	ZOOM=$2
	DIRNAME=$(dirname "$VRT")
	REPROJECTED_MERGED="${DIRNAME}/${REGION}_${ZOOM}_MOSAIC_${SRS_OUT}.tif"
	ZOOM_RESOLUTION=$(zoom_resolver $ZOOM)

	#reprojection job:
	gdalwarp \
	  -multi \
	  -wm $WARP_MEMORY \
	  -tr $ZOOM_RESOLUTION $ZOOM_RESOLUTION \
	  -tap \
	  -r $RESAMPLE_ALGO \
          -dstalpha \
	  -s_srs EPSG:"$SRS_IN" \
	  -t_srs EPSG:"$SRS_OUT" \
	  -wo SOURCE_EXTRA=16 \
	  -wo NUM_THREADS="$N_PROC" \
  	  -co COMPRESS=$COMPRESS_ALGO \
	  -co PREDICTOR=$PREDICTOR \
	  -co ZLEVEL=$COMPRESS_LEVEL \
	  -co TILED=YES \
	  -co BLOCKXSIZE=256 \
	  -co BLOCKYSIZE=256 \
	  -co NUM_THREADS="$N_PROC" \
	  -co BIGTIFF=YES \
	  -overwrite \
	  "$VRT" \
	  "$REPROJECTED_MERGED";
}


#fonction de reprojection:
function tile_clipper(){
	
	#processing elements:
	INPUT_LAYER=$1
	INDEX_BUFFER=$2
	INDEX_CROP=$3
	VRT=$4
	ZOOM=$5
	DIRNAME=$(dirname "$INPUT_LAYER")
	BASENAME=$(basename "$INPUT_LAYER" .tif)
	REPROJECTED_BUFFERED="${DIRNAME}/${BASENAME}_${SRS_OUT}_buffer.tif"
	REPROJECTED_CROPPED="${DIRNAME}/${BASENAME}_${SRS_OUT}.tif"
	CLIPPER="${INDEX_DIR}/clipper_${BASENAME}.geojson"
	ZOOM_RESOLUTION=$(zoom_resolver $ZOOM)
	#Log and progress elements:
	REGION=$(echo "${INPUT_LAYER}" | cut -d/ -f 8)
	DEPARTEMENT=$(echo "${INPUT_LAYER}" | cut -d/ -f 9)
	ZOOM_LEVEL_LOG=$(echo "${INPUT_LAYER}" | cut -d/ -f 10)
	RASTER=$(echo "${INPUT_LAYER}" | cut -d/ -f 11)

	echo -e "\nRegion: ${REGION}"
	echo "Departement: ${DEPARTEMENT}"
	echo "Zoom level: ${ZOOM_LEVEL_LOG}"
	echo "processing buffer zone for file: TIFF ${RASTER}"

	gdalwarp \
	  -multi \
	  -wm $WARP_MEMORY \
	  -tr $ZOOM_RESOLUTION $ZOOM_RESOLUTION \
	  -tap \
	  -r $RESAMPLE_ALGO \
          -dstalpha \
	  -s_srs EPSG:"$SRS_IN" \
	  -t_srs EPSG:"$SRS_OUT" \
	  -cutline "$INDEX_BUFFER" \
	  -crop_to_cutline \
	  -cwhere "location = '${INPUT_LAYER}'" \
	  -wo SOURCE_EXTRA=16 \
	  -wo NUM_THREADS="$N_PROC" \
  	  -co COMPRESS=ZSTD \
	  -co PREDICTOR=$PREDICTOR \
	  -co ZSTD_LEVEL=1 \
	  -co TILED=YES \
	  -co BLOCKXSIZE=256 \
	  -co BLOCKYSIZE=256 \
	  -co NUM_THREADS="$N_PROC" \
	  -co BIGTIFF=YES \
	  -overwrite \
	  "$VRT" \
	  "$REPROJECTED_BUFFERED";

	echo -e "cropping back to file extent: TIFF ${BASENAME}"

	if [[ -f $CLIPPER ]]
	then
		rm -rf "$CLIPPER";
	fi

	ogr2ogr \
		-t_srs EPSG:"$SRS_OUT" \
		-of 'GeoJSON' \
		"$CLIPPER" \
		"$INDEX_CROP" \
		-where "location='${INPUT_LAYER}'" \
		-nln 'clipper'

	Xmin=$(ogrinfo "$CLIPPER" clipper -json | jq -r '.layers[0].geometryFields[0].extent[0]');
	Ymax=$(ogrinfo "$CLIPPER" clipper -json | jq -r '.layers[0].geometryFields[0].extent[3]');
	Xmax=$(ogrinfo "$CLIPPER" clipper -json | jq -r '.layers[0].geometryFields[0].extent[2]');
	Ymin=$(ogrinfo "$CLIPPER" clipper -json | jq -r '.layers[0].geometryFields[0].extent[1]');

	#crop back to size
	gdal_translate \
	  --config GDAL_CACHEMAX $GDAL_MEMORY \
	  -projwin "$Xmin" "$Ymax" "$Xmax" "$Ymin" \
	  -projwin_srs EPSG:"$SRS_OUT" \
	  -co COMPRESS=$COMPRESS_ALGO \
	  -co PREDICTOR=$PREDICTOR \
	  -co ZLEVEL=$COMPRESS_LEVEL \
	  -co TILED=YES \
	  -co BLOCKXSIZE=$BLOCKSIZE \
	  -co BLOCKYSIZE=$BLOCKSIZE \
	  -co BIGTIFF=YES \
	  -co NUM_THREADS="$N_PROC" \
	  "$REPROJECTED_BUFFERED" \
	  "$REPROJECTED_CROPPED";

    # cleanup
    echo 'Triggering cleanup';

    # cleanup reprojected buffer rasters:
	if [[ -f $REPROJECTED_BUFFERED ]]
	then
		rm -rf "$REPROJECTED_BUFFERED";
	fi

	# cleanup clipper geojson files:
	if [[ -f $CLIPPER ]]
	then
		rm -rf "$CLIPPER";
	fi
}


# function that clips and reprojects individual
# shards preparing them to tile indexing
function shards_builder(){
	
	#create a reference to argument array
	declare -n REGTIFS_SRC="$1"
	#declare a read only indexed array and copy values:
	declare -ar REGTIFS=("${REGTIFS_SRC[@]}")
	ZOOM=$2
	VRT=$3
	# index variables:
	INDEX="${INDEX_DIR}/STAGED_${REGION}.shp"
	INDEX_BUFFERED="${INDEX_DIR}/STAGED_${REGION}_BUFFERED.shp"
	INDEX_SRS_OUT="${INDEX_DIR}/STAGED_${REGION}_${SRS_OUT}.shp"
	BUFFER=50

	echo -e '\n Building indexes for all involved rasters.'

	# build a tile index for buffered warping/reprojection:
	gdaltindex \
		-t_srs EPSG:"$SRS_IN" \
		-write_absolute_path \
		-overwrite \
		-src_srs_name src_srs \
		$INDEX \
		"${REGTIFS[@]}"

	# create buffered version
	ogr2ogr \
	  $INDEX_BUFFERED \
	  $INDEX \
	  -dialect SQLITE \
	  -sql "SELECT ST_Buffer(geometry, ${BUFFER}) AS geometry, * FROM $(basename $INDEX .shp)"

	echo -e '\n Building reprojected index for clipping purposes.'

	# reproject the index into $SRS_OUT
	ogr2ogr \
		-s_srs EPSG:"$SRS_IN" \
		-t_srs EPSG:"$SRS_OUT" \
		-of 'ESRI Shapefile' \
		$INDEX_SRS_OUT \
		$INDEX

	echo -e '\n Creating Reprojected GeoTIFF Raster from input ...'

	#parallel processing:
	export -f zoom_resolver
	export -f tile_clipper

	echo -e "\n Spawning parallel workers ... \n"
	parallel -j $JOBS \
	 "tile_clipper {1} ${INDEX_BUFFERED} ${INDEX_SRS_OUT} ${VRT} ${ZOOM}" \
	 	::: "${REGTIFS[@]}";

	echo -e '\n Raster creation complete.'

	echo -e '\n Triggering Raw data and index tools cleanup';

	for tif in "${REGTIFS[@]}"
	do
		rm -rf "$tif";
	done;

	#preparing indexes directories
	INDEX_DIRNAME=$(dirname "$INDEX")
	INDEX_BUFFERED_DIRNAME=$(dirname "$INDEX_BUFFERED")
	INDEX_SRS_OUT_DIRNAME=$(dirname "$INDEX_SRS_OUT")
	#preparing indexes names without extension
	INDEX_BASENAME=$(basename "$INDEX" .shp)
	INDEX_BUFFERED_BASENAME=$(basename "$INDEX_BUFFERED" .shp)
	INDEX_SRS_OUT_BASENAME=$(basename "$INDEX_SRS_OUT" .shp)
	#deleting complete index suite
	rm -rf $INDEX_DIRNAME/$INDEX_BASENAME.{shp,dbf,qix,shx,prj}
	rm -rf $INDEX_BUFFERED_DIRNAME/$INDEX_BUFFERED_BASENAME.{shp,dbf,qix,shx,prj}
	rm -rf $INDEX_SRS_OUT_DIRNAME/$INDEX_SRS_OUT_BASENAME.{shp,dbf,qix,shx,prj}

	echo -e '\n Cleanup complete.';
}


# function that builds index of all
# reprojected shards by shards_builder()
function tileindex_builder() {
	
	ZOOM=$1
	TILEINDEX=$2

	declare -a REGTIFS_SRC_OUT

	echo -e '\n Building tileindex of staged rasters'

	PATTERN="PLANIGN${ZOOM}_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]_L93_${SRS_OUT}.tif"

	for DEP in "${DEPTS[@]}"
	do
		DEPARTEMENT=$(printf "%02d" "$DEP")
		DEPARTEMENT=DEPARTEMENT_${DEPARTEMENT}
		ZOOM_FOLDER=ZOOM_$ZOOM
		deptpath=$WORKDIR/$RASTER_DIR/$REGION/$DEPARTEMENT/"$ZOOM_FOLDER"
		REGTIFS_SRC_OUT+=("$deptpath"/$PATTERN)
	done;

	# build a tile index:
	gdaltindex \
		-t_srs EPSG:"$SRS_OUT" \
		-write_absolute_path \
		-overwrite \
		-src_srs_name src_srs \
		"$TILEINDEX" \
		"${REGTIFS_SRC_OUT[@]}"

	echo ' Adding index tree to tile index ...'
	shptree "$TILEINDEX" 2> /dev/null
	echo ' Adding index tree complete.'

	echo " Successfully added these rasters to Mapservers Tile Index:"
	for tif in "${REGTIFS_SRC_OUT[@]}"
	do
		basename "$tif"
	done;

	echo -e '\n Creating tile index complete.';
}


###################################### MAIN JOB ############################################

# Main configuration variables:
REGION='IDF'
BASENAME=$REGION
INDEX_DIR="${RASTER_DIR}/${REGION}/${REGION}_TILEINDEX"
INPUT_VRT="${INDEX_DIR}/${BASENAME}.vrt"

# GDAL configuration knobs
RESAMPLE_ALGO=cubic
COMPRESS_ALGO=DEFLATE
COMPRESS_LEVEL=7
PREDICTOR=2
BLOCKSIZE=512
WARP_MEMORY=50
GDAL_MEMORY=50
JOBS=17

# export references to the parallel subshells:
export RESAMPLE_ALGO COMPRESS_ALGO COMPRESS_LEVEL INDEX_DIR WORKDIR SRS_IN
export PREDICTOR BLOCKSIZE WARP_MEMORY N_PROC JOBS GDAL_MEMORY SRS_OUT

echo -e "\n =================== Starting raw data extraction ... ==========================\n"
# variables de controle de flux:
DEPTS=(75 77 78 91 92 93 94 95)
#DEPTS=(75)
 
ZOOM_LEVELS=({08..19})

#restreindre a la generation des indexes
#et les niveaux de zoom de bas niveau: 
#mettre YES pour restrindre
BUILD_TINDEX_ONLY=

# desarchiver la donnee raster IGN
unzip_rasters ZIP_DL;

# create index folder
mkdir -p $INDEX_DIR

echo -e "\n =================== Starting main jobs ==========================\n"


for ZOOM_LEVEL in "${ZOOM_LEVELS[@]}"
do
	echo -e "\n Processing Zoom Level ${ZOOM_LEVEL}\n"
	# declare zoom level tileindex name
	TILEINDEX="${INDEX_DIR}/${REGION}_TILEINDEX_${ZOOM_LEVEL}.shp"
	# List all region tifs:
	# indexed array to host tif names:
	declare -a REGTIFS
	# create input tile search pattern
	PATTERN="PLANIGN${ZOOM_LEVEL}_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]_L93.tif"

	#fill an array with zoom level shards:
	for DEP in "${DEPTS[@]}"
	do
		DEPARTEMENT=$(printf "%02d" "$DEP")
		DEPARTEMENT=DEPARTEMENT_${DEPARTEMENT}
		ZOOM_FOLDER=ZOOM_$ZOOM_LEVEL
		deptpath=$WORKDIR/$RASTER_DIR/$REGION/$DEPARTEMENT/"$ZOOM_FOLDER"
		REGTIFS+=("$deptpath"/$PATTERN)
	done;

	echo -e '\n Creating Virtual Mosaic for all involved rasters.'
	# build a coherent virtual layer
	# echo "${REGTIFS[@]}"
	gdalbuildvrt -addalpha -resolution highest $INPUT_VRT "${REGTIFS[@]}"

	if [[ $ZOOM_LEVEL == 0[8-9] || $ZOOM_LEVEL == 1[0-5] ]]
	then
		if [[ "$BUILD_TINDEX_ONLY" == 'YES' ]]
		then
			echo -e "\n Building Tileindex Only. Skipping Merge ..."
		else
			# tile merge here
			echo -e "\n Creating Mosaic for Zoom ${ZOOM_LEVEL} for rasters ...\n"
			for tif in "${REGTIFS[@]}"
			do
				echo $(basename "$tif");
			done;

		        tile_merger $INPUT_VRT $ZOOM_LEVEL;

		fi
	elif [[ $ZOOM_LEVEL == 1[6-9] ]]
	then
		#======================  Tileindex Reprojected Shards building ====================#
		if [[ "$BUILD_TINDEX_ONLY" == 'YES' ]]
		then
			echo -e "\n Building Tileindex Only. Skipping Shards Reprojection ..."
		else
			shards_builder REGTIFS $ZOOM_LEVEL $INPUT_VRT;
		fi
		#============================  Shards Reprojection ends ===========================#

		#===========================  tile indexing here ==================================#
		tileindex_builder $ZOOM_LEVEL "$TILEINDEX"
		#=============================== indexing end =====================================#
	else
		echo -e "\n Zoom level out of normal range. Exit ..."
		exit -9;
	fi

	#unsetting global arrays:
	unset REGTIFS
	#adding access to Apache (user is in the apache group)
	chmod -R 775 ./**


	echo -e "\n ============== End ==================\n";

done;

echo -e '\n creating project tree'
tree $RASTER_DIR/$REGION > "${INDEX_DIR}/${REGION}_tree.txt"


#EOS

