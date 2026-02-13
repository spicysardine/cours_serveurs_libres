#!/bin/bash

OUTPUT_DATABASE='geofab'
OUTPUT_SCHEMA='raster'
OUTPUT_SRS=4326

shopt -s extglob

# nettoyage du répertoire de travail
rm +(*tif|*zip)

BASE_URL="https://srtm.csi.cgiar.org/wp-content/uploads/files/srtm_5x5/TIFF/"

ROWS=($(seq 1 5))
COLS=($(seq 1 26))

# approche séquentielle (lente)
#for row in ${ROWS[@]}
#do
#	for col in ${COLS[@]}
#	do
#		col=$(printf "%02d\n" $col)
#		row=$(printf "%02d\n" $row)
#		wget --no-check-certificate \
#			"${BASE_URL}srtm_${col}_${row}.zip"
#	done;
#done;

#ls *zip | while read zipfile
#	do
#		unzip -j -o $zipfile "*tif" 
#	done;

# approche de téléchargement en parallèle:
parallel -j $(nproc) \
	"wget --no-check-certificate ${BASE_URL}srtm_{1}_{2}.zip" \
	::: $(printf "%02d\n" ${COLS[@]}) \
	::: $(printf "%02d\n" ${ROWS[@]})

# desarchivage en masse
ls *zip | parallel -j $(nproc) \
	"unzip -j -o {} '*tif'" 



## insertion d’un fichier raster en WGS84 dans la BDD à l’aide de raster2pgsql
## avec tuilage automatique
## -s: spécifier le CSRS
## -I: mettre en place un index
## -M: accompagner d’un vacuum pour ganger en espace de stockage
## -C: ajouter des contraintes de type sur la colonne raster dans la BDD
## -F: mettre l’intitulé du fichier comme nom de la colonne
## -t: spécifier les dimensions du tuilage tuilage

# approche séquentielle
#raster2pgsql -s 4326 -I -M -C -F -t 500x500 *.tif | psql -d beetroot

# approche parallèle d'insertion:
ls *tif | parallel -j $(nproc) \
"raster2pgsql -s ${OUTPUT_SRS} -I -M -C -F -t 500x500 ${OUTPUT_SCHEMA}.{} | psql -d ${OUTPUT_DATABASE}"

# génératin de mosaique virtuelle
gdalbuildvrt  canada.vrt *tif

gdalwarp -of GTIFF -t_srs EPSG:3348 -r bilinear canada.vrt canada.tif

gdaldem hillshade -of GTIFF canada.tif -az 315 -alt 45 canada_hillsade.tif

gdaldem slope -of GTIFF canada.tif canada_slope.tif

gdaldem color-relief -of GTIFF canada.tif color_relief.txt -alpha canada_color_relief.tif

# calcul de la couche de relief colorée
gdal_calc -A canada_color_relief.tif --allBands=A -H canada_hillsade.tif --type=Byte --outfile=color_shaded_relief.tif --calc='A*(H/255)'












