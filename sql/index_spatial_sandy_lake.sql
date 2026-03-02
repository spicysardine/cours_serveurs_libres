-- index spatial script
/*
create table geography.clr_ls as 
SELECT
row_number() over() as id,
hydrouid,
name,
pruid, 
st_transform(wkb_geometry, 3348) as geom
from geography."clr_ls.shp_3348"
order by id;

select 
*
from geography.clr_ls
where name ~* 'sandy'


SELECT
row_number() over() as id,
st_envelope(geom) as geom
FROM geography.clr_ls
ORDER BY id
;


SELECT
1 as id,
st_envelope(geom) as geom
FROM geography.clr_ls
where id = 2396
ORDER BY id
;

SELECT
1 as id,
st_centroid(geom) as geom
FROM geography.clr_ls
where id = 2396
ORDER BY id
;


-- bbox de recherche spatiale:
EXPLAIN analyze
WITH centroid as (
	select
	1 as id,
	st_centroid(geom) as geom
	FROM geography.clr_ls
	where id = 2396
)
SELECT
1 as id,
st_expand(centroid.geom, 320000) as geom
from centroid
;



WITH centroid as (
	select
	1 as id,
	st_centroid(geom) as geom
	FROM geography.clr_ls
	where id = 2396
)
SELECT
1 as id,
st_buffer(centroid.geom, 300000, 'quad_segs=1') as geom 
from centroid
;
*/


-- bbox de recherche spatiale:
--EXPLAIN analyze
WITH centroid as (
	select
	1 as id,
	st_centroid(geom) as geom
	FROM geography.clr_ls
	where id = 2396
)
SELECT
row_number() over() as id,
clr.name,
ROUND((c.geom <-> clr.geom)::NUMERIC/1000, 2) as dist_km,
clr.geom
from 
geography.clr_ls as clr,
centroid as c
WHERE 
st_expand(c.geom, 300000) ~ clr.geom
AND name is not null
ORDER BY dist_km asc
;

--CREATE INDEX ON geography.clr_ls USING GIST(geom);
















