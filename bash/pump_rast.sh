#!/bin/bash

X_RANGE=$(seq 10 22)
Y_RANGE=$(echo {L..T})

# URL du site web de téléchargement
URL="http://viewfinderpanoramas.org/dem3"

# Methode 1 téléchargement en parallel
parallel -j$(nproc) "wget --no-check-certificate  $URL/{1}{2}.zip" ::: $Y_RANGE ::: $X_RANGE 2> err_out.log


# Method 2 téléchargement en boucle
for X in $X_RANGE
do
	for Y in $Y_RANGE 
	do 
		wget --no-check-certificate  "$URL/$Y$X".zip;
	done
done


# étapes

# désarchivage des fichiers
ls *zip | parallel -j$(nproc) "unzip -j -o {} '*hgt'"


# Mosaicage dans une couche virtuelle
gdalbuildvrt canada.vrt *hgt

# Reprojection de la couche virtuelle dans un fichier GeoTIFF
# La reprojection est obligatoire pour éviter d’obtenir des images corrompues
# noter que les fichiers MNT SRTM ne sont pas projetés
gdalwarp -t_srs EPSG:3348 -r bilinear canada.vrt canada.tif

# Obtenir des informations sur le fichier
gdalinfo -mm canada.tif

# Génération du fichier hillshade (reliefs ombragés)
gdaldem hillshade -of GTIFF -az 135 canada.tif canada_hillshade.tif

# Génération du fichier de reliefs colorés color-relief
gdaldem color-relief canada.tif color_relief.txt canada_color_relief.tif

# Génération du fichier de pente
gdaldem slope canada.tif canada_slope.tif

# Génération du fichier de pente coloré
gdaldem color-relief -of GTIFF canada_slope.tif color_slope.txt canada_slopeshade.tif



