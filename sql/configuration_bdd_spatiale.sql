/**********************   SQL script ***********************/

/**************************** Database Setup & Analysis *************************************/
-- create DATABASE nom_de_base; (mettez le nom que vous voulez)
-- créer vos schema de travail. Surtout le schema PostGIS qui accueillera l’extension PostGIS
CREATE schema geography;
CREATE schema postgis;
CREATE schema pgrouting;
CREATE schema rasters;
CREATE schema gis;


-- afficher le search_path actuel
SHOW search_path;

-- changer le search_path 
ALTER database nom_de_base SET search_path TO "$user", public, postgis, geography, gis, pgrouting;

-- déconnecter puis reconnecter le serveur PostgreSQL.
-- vérifier la prise en compte du changement
SHOW search_path;

-- Création de l’extension PostGIS dans le schema PostGIS
CREATE extension postgis schema postgis;

-- vérification de la version
SELECT POSTGIS_FULL_VERSION();

-- Activer le support des rasters (pour les version 3+)
-- Remarque: Obligatoirement dans le meme schema que PostGIS
CREATE EXTENSION postgis_raster schema postgis;

-- En cas de besoin créer l’extension pgrouting
CREATE extension pgrouting schema pgrouting;

-- En cas de besoin activer Topology
CREATE SCHEMA topology;
CREATE EXTENSION postgis_topology schema topology;

-- Vérifier que la BDD spatiale est activée en créant un point géo-référencé
SELECT ST_GeomFromText('POINT(2.22 48.85)', 4326);
