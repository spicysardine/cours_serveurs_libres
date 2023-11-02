#!/bin/bash




#lister le contenu du répertoire courant
ls -l

#mettre à jour le fichier de définitions des paquets
sudo apt update

# mettre à jour les paquets du système
sudo apt full-upgrade

#installer un paquet logiciel avec apt
sudo apt install  nom_du_paquet

#installer un fichier deb
sudo dpkg -i paquet.deb

#ajouter UbuntuGIS (Stable) au fichier de définitions
sudo add-apt-repository ppa:ubuntugis/ppa

# mettre à jour le système
sudo apt update

# insaller qgis
sudo apt install qgis

# installer PostgreSQL
# exemple pour ubuntu 20.04/popOS! (la version peut changer selon les version de l’OS)
sudo apt install postgresql-12

# installer postgis (il ne fait pas partie des dépendance de postgresql. Il faut donc l’insaller indépendamment)
# exemple pour ubuntu 20.04/popOS! (la version peut changer selon les version de l’OS)
sudo apt install postgresql-12-postgis-3

# installer postgis version binaire appelable depuis la ligne de commande
sudo apt install postgis

# installer mapserver
# exemple pour ubuntu 20.04/popOS! (la version peut changer selon les version de l’OS)
sudo apt install mapserver-bin cgi-mapserver

# insaller php
# exemple pour ubuntu 20.04/popOS! (la version peut changer selon les version de l’OS)
sudo apt install php7.4

# installer le serveru apache2
# remarque si php est installé apache2 sera installé automatiquement car faisant partie des dépendances
sudo apt install apache2

# installer la version binaire appelable depuis la ligne de commande
sudo apt install gdal-bin

# obtenir de l’aide et plus d’informations sur une commande
man commande

# ou
commande --help

#ou 
commande -h

# exemple
man shp2pgsql


# insertion d’un shape avec shp2pgsql si la projection d’origine est en WGS84 
# et l’encodage système est en UTF8 (changer en accordance car les shape sont en LATIN1 par défaut)
# -s: spécifier le CSRS
# -I: mettre en place un index
# -W: système d’encodage
shp2pgsql -s 4326 -I -W 'UTF8' nom_du_shape.shp | psql -d nom_de_base

# insertion d’un shape avec shp2pgsql si la projection d’origine est en WGS84 
# mais que vous voulez reprojeter la donnée (ici exemple du CRS officiel du Canada)
# et l’encodage système est en UTF8 (changer en accordance car les shape sont en LATIN1 par défaut)
shp2pgsql -s 4326:3348 -I -W 'UTF8' nom_du_shape.shp | psql -d nom_de_base

# insertion d’un shape avec shp2pgsql si la projection d’origine est en WGS84 
# mais que vous voulez reprojeter la donnée (ici exemple du CRS officiel du Canada)
# et que vous voulez spécifier la table d’accueil du schema geography
# et l’encodage système est en UTF8 (changer en accordance car les shape sont en LATIN1 par défaut)
shp2pgsql -s 4326:3348 -I -W 'UTF8' nom_du_shape.shp geography.nouveau_nom_du_shape | psql -d nom_de_base

# insertion d’un fichier raster en WGS84 dans la BDD à l’aide de raster2pgsql
# avec tuilage automatique
# -s: spécifier le CSRS
# -I: mettre en place un index
# -M: accompagner d’un vacuum pour ganger en espace de stockage
# -C: ajouter des contraintes de type sur la colonne raster dans la BDD
# -F: mettre l’intitulé du fichier comme nom de la colonne
# -t: spécifier les dimensions du tuilage tuilage
raster2pgsql -s 4326 -I -M -C -F -t auto nom_du_raster.tif | psql -d nom_de_base

# insertion d’un fichier raster en WGS84 dans la BDD à l’aide de raster2pgsql
# avec un découpage en tuiles de 100x100 pixels dans une table précise dans le schema rasters 
raster2pgsql -s 4326 -I -M -C -F -t 100x100 nom_du_raster.tif rasters.nom_de_table | psql -d nom_de_base

# remarque: pour lister les rasters dispoinible dans la base concernée dans postgresql
select * from raster_columns;


















