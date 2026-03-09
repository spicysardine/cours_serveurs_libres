select 
id,
name,
nom as name_fr,
st_makeValid(geom) as geom
from geography.canada_wgs84
;


select 
1 as id,
st_Envelope(
	st_collect(
	st_transform(geom, 3857)
	)
) as geom
from geography.canada_wgs84
;



select 
1 as id,
st_Extent(
st_Envelope(
	st_collect(
	st_transform(geom, 3857)
	)
) 
)as geom
from geography.canada_wgs84
;

SELECT ogc_fid, st_MakeValid(geom) as geom 
FROM geography.cb_2018_us_state_5m_3348


CREATE OR REPLACE FUNCTION validate_ref()
RETURNI
$$
$$













