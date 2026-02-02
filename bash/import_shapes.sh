#!/bin/bash

# nettoyage du repertoire en de travail
shopt -s extglob
rm !(*sh|*zip)

INPUT_DATABASE=geofab
INPUT_SCHEMA=geography
OUTPUT_SRS=EPSG:3857
INPUT_DRIVER='ESRI Shapefile'
OUTPUT_DRIVER='PostgreSQL'

ls *zip

# désarchiver les fichiers de forme
for zipfile in *.zip;
do
	unzip -j -o "$zipfile";
done;

# récupérer la métadonnée de projection
ls -l *.shp


# fonction de récupération du système de projection
function get_srs(){
	srs=$(gdalsrsinfo -o epsg "$1" 2> /dev/null | grep 'EPSG' || echo "EPSG:4326")
	echo "$srs"
}


# fonction de récupération du type géométrique
function get_geometry_type(){
	geomtype=$(ogrinfo \
		-so -json \
		"$1" 2> /dev/null | jq -r ".layers[0].geometryFields[0].type")
	echo $geomtype
}


function get_feature_count(){
	featcount=$(ogrinfo \
	-so -json \
	"$1" 2> /dev/null | jq -r ".layers[0].featureCount")
	echo $featcount
}

# reprojection et insertion dans la BDD
function insert_layer_into_db(){
	shapefile=$1
	echo "----------$shapefile------------"
	BASENAME=$(basename "$shapefile" .shp)
	SRS=$(get_srs $shapefile)
	GEOMTYPE=$(get_geometry_type $shapefile | tr '[:lower:]' '[:upper:]')
	ENCODING=$(uchardet "$BASENAME".dbf)
	FEATCOUNT=$(get_feature_count $shapefile)
	echo "La couche contient $FEATCOUNT géométries"
	echo "Le système de projection est: $SRS"
	echo "Le type géométrique est: $GEOMTYPE"
	echo "L'encodage est en: $ENCODING"
	
	# insertion dans la BDD géospatiale:
	ogr2ogr \
		-s_srs $SRS \
		-t_srs $OUTPUT_SRS \
		-of $OUTPUT_DRIVER PG:"dbname=$INPUT_DATABASE" \
		-if "$INPUT_DRIVER" $shapefile \
		-nln "$INPUT_SCHEMA.${shapefile// /_}" \
		-nlt $GEOMTYPE \
		-oo ENCODING:"$ENCODING" \
		-emptyStrAsNull \
		-progress
#		-nlt PROMOTE_TO_MULTI \
}

for shapefile in *.shp;
do
	insert_layer_into_db	$shapefile
	echo -e '\n'
done;


