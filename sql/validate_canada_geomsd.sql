-- Validate geofab geoms
select 
id,
name,
nom as name_fr,
st_makeValid(geom) as geom
from geography.canada_wgs84
;


create table geography.canada_wgs84_valid as
select 
id as id,
name,
nom as name_fr,
st_makeValid(geom) as geom
from geography.canada_wgs84
;

--