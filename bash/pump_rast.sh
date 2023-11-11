#!/bin/bash

URL="https://srtm.csi.cgiar.org/wp-content/uploads/files/srtm_5x5/TIFF"
THREADS=$(nproc)


#preparation des tableaux
COLUMNS=($(seq 10 26))
ROWS=($(seq 1 4))

##Méthode séquencielle (classique):
#for row in ${ROWS[@]}
#do
#	for column in ${COLUMNS[@]};
#	do
#		wget --no-check-certificate "${URL}/srtm_${column}_0${row}.zip" 2> out.log;
#	done
#done


#Méthode parallèle:
parallel -j $THREADS "wget --no-check-certificate ${URL}/srtm_{1}_0{2}.zip" ::: $(echo ${COLUMNS[@]}) ::: $(echo ${ROWS[@]})

# étapes

# désarchivage des fichiers
ls *zip | parallel -j $THREADS "unzip -j -o {} '*tif'"


## Mosaicage dans une couche virtuelle
gdalbuildvrt canada.vrt *tif

## Reprojection de la couche virtuelle dans un fichier GeoTIFF
## La reprojection est obligatoire pour éviter d’obtenir des images corrompues
## noter que les fichiers MNT SRTM ne sont pas projetés
gdalwarp -t_srs EPSG:3348 -r bilinear canada.vrt canada.tif 

## Obtenir des informations sur le fichier
#gdalinfo -mm canada.tif

## Génération du fichier hillshade (reliefs ombragés)
gdaldem hillshade -of GTIFF -az 315 -alt 45 canada.tif canada_hillshade.tif

## Génération du fichier de reliefs colorés color-relief
gdaldem color-relief canada.tif color_relief.txt canada_color_relief.tif

## Génération du fichier de pente
gdaldem slope canada.tif canada_slope.tif

## Génération du fichier de pente coloré
gdaldem color-relief -of GTIFF canada_slope.tif color_slope.txt canada_slopeshade.tif






















































