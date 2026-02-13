#!/bin/bash

OUTPUT_SRS="EPSG:3348"
DEFAULT_SRS="EPSG:4326"
DATABASE='geofab'
OUTPUT_SCHEMA='geography'

OUTPUT_DRIVER='PostgreSQL'
INPUT_DRIVER='ESRI Shapefile'

function getInputSRS(){
	SHAPEFILE="$1"
	
	INPUT_SRS=$(gdalsrsinfo \
		-o epsg "$SHAPEFILE" \
		2> insertion_log.log \
		| grep -i -E 'epsg|esri' || echo "$DEFAULT_SRS" )
	# retourner le résultat
	echo "$INPUT_SRS"
}


function getInputSRS_json(){
	SHAPEFILE="$1"
	# récupération de la projection en utilisant
	# un objet JSON
	INPUT_SRS=$(ogrinfo \
		-so -json \
		"$SHAPEFILE" \
		| jq -r\
		".layers[0].geometryFields[0].coordinateSystem.projjson.id.code")
	echo "EPSG:$INPUT_SRS"
}


function getGeometryType(){
	SHAPEFILE="$1"
	# récupération du type géométrique
	# à partir d'un objet JSON
	GEOMETRY_TYPE=$(ogrinfo \
		-so -json \
		"$SHAPEFILE" \
		| jq -r \
		".layers[0].geometryFields[0].type" \
		| tr '[:lower:]' '[:upper:]')
	echo "$GEOMETRY_TYPE"
}


function getISOEncoding(){
	SHAPEFILE="$1"
	# récupération de l'encodage text
	# à partir d'un objet JSON
	ENCODING=$(ogrinfo \
		-so -json \
		"$SHAPEFILE" \
		| jq -r \
		".layers[0].metadata.SHAPEFILE.SOURCE_ENCODING" )
	echo "$ENCODING"
}


function getISOEncodingFast(){
	SHAPEFILE="$1"
	# récupération de l'encodage texte
	# directement à partir de la base dbf
	LAYER_NAME=$(basename "$SHAPEFILE" '.shp')
	ENCODING=$(uchardet ${LAYER_NAME}'.dbf')
	echo $ENCODING
}


function getFeatureCount(){
	SHAPEFILE="$1"
	# récupération du nombre de géométries
	# à partir d'un objet JSON
	FEATCOUNT=$(ogrinfo \
		-so -json \
		"$SHAPEFILE" \
		| jq \
		".layers[0].featureCount")
	echo "$FEATCOUNT"
}


echo "Début d'insertion de la couche:"

function insert_layer(){
	
	
	#déclaration des variables:
	SHAPEFILE=$1
	INPUT_NAME=$(basename "$SHAPEFILE" '.shp')
	INPUT_NAME="${SHAPEFILE// /_}"
	INPUT_SRS=$(getInputSRS "$SHAPEFILE")
	GEOMTYPE=$(getGeometryType "$SHAPEFILE")
#	echo $GEOMTYPE
	ENCODING=$(getISOEncodingFast "$SHAPEFILE")
	FEATCOUNT=$(getFeatureCount "$SHAPEFILE")
	
	echo -e "_____________${INPUT_NAME}___________________\n"
	echo -e "Système de projection de la chouche ${INPUT_SRS}.\n"
	echo -e "La couche est de géométrie de type ${GEOMTYPE}.\n"
	echo -e "La couche est encodée en ${ENCODING} .\n"
	echo -e "La couche contient: ${FEATCOUNT} ${GEOMTYPE}\n"
	# définition de la projection source 
	# définition de la projection cible
	# format en sortie de l'opération
	# format en entrée de la couche
	# nom de la chouche dans la BDDG
	# type géométrique
	#-nlt PROMOTE_TO_MULTI \
	# options d'écriture
	ogr2ogr \
	-s_srs "$INPUT_SRS" \
	-t_srs "$OUTPUT_SRS" \
	-of "$OUTPUT_DRIVER" PG:"dbname=${DATABASE}" \
	-if "$INPUT_DRIVER" "$SHAPEFILE" \
	-nln "$OUTPUT_SCHEMA"."${INPUT_NAME}_3348" \
	-nlt "$GEOMTYPE" \
	-emptyStrAsnull \
	-oo ENCODING:"$ENCODING" \
	-progress
}

# nettoyage du plan de travail:
shopt -s extglob
rm -rf !(*sh|*zip)
sleep 3

# extraction des archives des couches 
ls *zip | parallel \
	"unzip -j -o {}"

# Début du programme d'insertion

for shapefile in *shp
do
	insert_layer $shapefile
done;







