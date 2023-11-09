-- canada raster analysis
CREATE TABLE rasters.test AS
SELECT 
* 
FROM
rasters.canada_color_relief_terrain
LIMIT 111
;

-- DROP TABLE geography.canada_basemap_simplified;
CREATE TABLE geography.canada_basemap_simplified AS
SELECT 
1 AS id,
ST_MakeValid(
	ST_SIMPLIFY(geom, 0.001)
) AS geom
FROM geography.canada_basemap
;








































































 
































