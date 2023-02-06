-- Fichier décrivant une fonction plpgsql
-- qui récupère et filtre la donnée d’une table spatiale (polygones des lacs du Canada)
-- transforme son CRS et retrourne le résultat filtré et transformé 
-- dans une limite de 500 enregistrements aléatoires.


CREATE OR REPLACE FUNCTION ma_fonction()
RETURNS TABLE(gid INTEGER, hydroname VARCHAR, hydrouid VARCHAR, pruid VARCHAR, geom GEOGRAPHY) AS
$$
DECLARE
REC     geography.clr%ROWTYPE;
REC_OUT RECORD;
BEGIN
	FOR REC IN (SELECT * FROM  geography.clr 
				WHERE name IS NOT NULL
				ORDER BY RANDOM()
				LIMIT 500)
	--
	LOOP
 		RAISE NOTICE 'NOM % ', REC.name;
		gid        := REC.id;
		hydroname  := REC.name;
		hydrouid   := REC.hydrouid;
		pruid      := REC.pruid;
		geom       := ST_TRANSFORM(REC.wkb_geometry, 4326);

		-- Chaque enregistrement OUT est retourné à un la fois
		RETURN NEXT;

	END LOOP;
	--

	-- ici RETURN est obligatoire et signale la fin de la fonction.
	RETURN;

END;
$$ LANGUAGE PLPGSQL PARALLEL SAFE;
---------------------------------------------

-- DROP FUNCTION ma_fonction();


-- à décommenter pour créer une nouvelle table avec le résultat de la fonction
-- CREATE TABLE clr_random_filtered AS
SELECT * FROM ma_fonction();





