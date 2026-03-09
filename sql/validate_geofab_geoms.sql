/*select 
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
*/



-- drop function validate_ref();
-- drop procedure validate_ref();

CREATE OR REPLACE PROCEDURE validate_ref() AS
$$
DECLARE
REC_TABLE RECORD;
REC_COLUMN RECORD;
BEGIN
	FOR REC_TABLE IN (
		SELECT
		 table_catalog,
		 table_schema,
		 table_name
		FROM information_schema.tables
		WHERE table_catalog = 'geofab'
		AND table_schema = 'geography'
		--AND table_name in ('clr_ls', 'clr_wgs84' )
		AND table_name ~ '_web$'
		ORDER BY table_name
	)
	LOOP
	--
		RAISE INFO '%:', REC_TABLE.table_name;
		FOR REC_COLUMN IN (
			SELECT
			 column_name,
			 data_type,
			 udt_name
			FROM information_schema.columns
			WHERE table_catalog = 'geofab'
			AND table_schema = 'geography'
			AND table_name = REC_TABLE.table_name
			ORDER BY column_name
		)
		LOOP
		--
			RAISE INFO '------>%', REC_COLUMN.column_name;
			IF REC_COLUMN.column_name = 'gid' THEN
				EXECUTE FORMAT($e$
					ALTER TABLE %s
					RENAME COLUMN gid to geo_id
				$e$, REC_TABLE.table_name);
				COMMIT;
			END IF;
			--
			IF REC_COLUMN.column_name = 'id' THEN
				EXECUTE FORMAT($e$
					ALTER TABLE %s
					RENAME COLUMN id to gid
				$e$, REC_TABLE.table_name);
				COMMIT;
			END IF;
			--
			IF REC_COLUMN.column_name = 'ogc_fid' THEN
				EXECUTE FORMAT($e$
					ALTER TABLE %s
					RENAME COLUMN ogc_fid to id
				$e$, REC_TABLE.table_name);
				COMMIT;
			END IF;
			--
			IF REC_COLUMN.column_name = 'geom' 
			AND REC_COLUMN.data_type = 'USER-DEFINED' 
			AND REC_COLUMN.udt_name = 'geometry' 
			THEN
				RAISE INFO '------> @@@@@@@@@ VALIDATING GEOMETRY @@@@@@@@ <-----------';
				BEGIN
					EXECUTE FORMAT($e$
						UPDATE %s
						SET geom = ST_MakeValid(geom)
					$e$, REC_TABLE.table_name);
					COMMIT;
				EXCEPTION
					WHEN others THEN
						CONTINUE;
				END;
			END IF;
		--	
		END LOOP;
	--
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
------------------------------------------------------------------------

CALL validate_ref()
;


-- DO $$ 
-- DECLARE 
--     r RECORD; 
-- BEGIN 
--     FOR r IN SELECT tablename FROM pg_tables WHERE tablename LIKE '%__3348' LOOP 
--         EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE'; 
--     END LOOP; 
-- END $$;













