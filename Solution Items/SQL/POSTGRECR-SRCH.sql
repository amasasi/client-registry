﻿/* 
 * POSTGRECR - MARC-HI CLIENT REGISTRY SEARCH FUNCTIONS FOR POSTGRESQL
 * VERSION: 2.0
 * AUTHOR: JUSTIN FYFE
 * DATE: JULY 12, 2012
 * FILES:
 *	POSTGRECR-DDL.SQL	- SQL CODE TO CREATE TABLES, INDECIES, VIEWS AND SEQUENCES
 *	POSTGRECR-SRCH.SQL	- SQL CODE TO CREATE SEARCH FUNCTIONS
 *	POSTGRESHR-FX.SQL	- SQL CODE TO CREATE SUPPORT PROCEDURES AND FUNCTIONS
 * DESCRIPTION:
 *	THIS FILE CLEANS AND THEN RE-CREATES THE POSTGRESQL CLIENT REGISTRY
 *	DATABASE SCHEMA INCLUDING TABLES, VIEWS, INDECIES AND SEQUENCES. 
 * LICENSE:
 * 	Licensed under the Apache License, Version 2.0 (the "License");
 * 	you may not use this file except in compliance with the License.
 * 	You may obtain a copy of the License at
 *
 *     		http://www.apache.org/licenses/LICENSE-2.0
 *
 * 	Unless required by applicable law or agreed to in writing, software
 * 	distributed under the License is distributed on an "AS IS" BASIS,
 * 	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * 	See the License for the specific language governing permissions and
 * 	limitations under the License.
 */

-- @FUNCTION 
-- FIND NAME COMPONENTS WITH A SIMILAR SOUNDING PARTS
CREATE OR REPLACE FUNCTION FIND_NAME_CMP_LIKE (
	NAME_VALUE_IN		IN VARCHAR(256),
	NAME_CMP_CLS_IN		IN DECIMAL(4),
	NAME_MIN_MATCH_IN	IN DECIMAL(1)
) RETURNS TABLE 
(
	NAME_SET_ID 	DECIMAL,
	SCORE 		INT
) 
AS
$$
BEGIN
	RETURN QUERY SELECT NAME_CMP_TBL.NAME_SET_ID, DIFFERENCE(NAME_VALUE_IN, NAME_CMP_VALUE) FROM NAME_CMP_TBL 
		WHERE DIFFERENCE(NAME_VALUE_IN, NAME_CMP_VALUE) >= NAME_MIN_MATCH_IN AND
			NAME_CMP_CLS = NAME_CMP_CLS_IN;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- FIND NAME SETS
CREATE OR REPLACE FUNCTION FIND_NAME_SET(
	NAME_CMP_VAL_IN	IN VARCHAR[],
	NAME_CMP_CLS_IN IN DECIMAL[],
	NAME_MIN_MATCH_IN IN DECIMAL(1)
) RETURNS TABLE (NAME_SET_ID DECIMAL(20,0)) AS
$$
DECLARE
	CNCMP	DECIMAL;
BEGIN

	-- CREATE TEMP TBLS
	IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'tmp_name_res_tbl') = 1) THEN
		DROP TABLE TMP_NAME_RES_TBL;
		DROP TABLE TMP_NAME_RET_TBL;
	END IF;
	
	CREATE LOCAL TEMPORARY TABLE TMP_NAME_RES_TBL (
		NAME_SET	DECIMAL(20,0)
	) ON COMMIT DROP;
	CREATE LOCAL TEMPORARY TABLE TMP_NAME_RET_TBL (
		NAME_SET	DECIMAL(20,0)
	) ON COMMIT DROP;
	
	-- FILTER THE FIRST SET
	INSERT INTO TMP_NAME_RET_TBL
		SELECT DISTINCT A.NAME_SET_ID 
		FROM NAME_CMP_TBL A 
		WHERE
			DIFFERENCE(NAME_CMP_VALUE, NAME_CMP_VAL_IN[1]) >= NAME_MIN_MATCH_IN
		AND
			NAME_CMP_CLS = NAME_CMP_CLS_IN[1];

	-- SUBSEQUENT
	IF(ARRAY_LOWER(NAME_CMP_VAL_IN, 1) < ARRAY_UPPER(NAME_CMP_VAL_IN, 1)) THEN
		FOR CNCMP IN ARRAY_LOWER(NAME_CMP_VAL_IN, 1) + 1 .. ARRAY_UPPER(NAME_CMP_VAL_IN, 1) LOOP
			INSERT INTO TMP_NAME_RES_TBL 
				SELECT DISTINCT A.NAME_SET_ID 
				FROM NAME_CMP_TBL A
				WHERE
					DIFFERENCE(NAME_CMP_VALUE, NAME_CMP_VAL_IN[CNCMP]) >= NAME_MIN_MATCH_IN
				AND
					NAME_CMP_CLS = NAME_CMP_CLS_IN[CNCMP]
			INTERSECT ALL
				SELECT A.NAME_SET FROM TMP_NAME_RET_TBL A;

			-- ADD RESULTS
			DELETE FROM TMP_NAME_RET_TBL;
			INSERT INTO TMP_NAME_RET_TBL 
				SELECT * 
				FROM TMP_NAME_RES_TBL;
			DELETE FROM TMP_NAME_RES_TBL;
		END LOOP;
	END IF;
	
	RETURN QUERY SELECT NAME_SET AS "NAME_SET_ID" FROM TMP_NAME_RET_TBL;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- FIND PERSON WITH SPECIFIED NAME SET
CREATE OR REPLACE FUNCTION FIND_PSN_BY_NAME_SET
(
	NAME_CMP_VAL_IN	IN VARCHAR[],
	NAME_CMP_CLS_IN IN DECIMAL[],
	NAME_SET_USE_IN	IN DECIMAL,
	NAME_MIN_MATCH_IN IN DECIMAL(1)
) RETURNS TABLE (PSN_ID DECIMAL(20,0)) AS
$$
BEGIN
	RETURN QUERY SELECT DISTINCT PSN_NAME_SET_TBL.PSN_ID FROM PSN_NAME_SET_TBL INNER JOIN FIND_NAME_SET(NAME_CMP_VAL_IN, NAME_CMP_CLS_IN, NAME_MIN_MATCH_IN) USING (NAME_SET_ID)
		WHERE 
			(NAME_SET_USE_IN IS NOT NULL AND NAME_SET_USE = NAME_SET_USE_IN OR NAME_SET_USE_IN IS NULL) 
			AND
			OBSLT_VRSN_ID IS NULL;
		
END
$$ LANGUAGE plpgsql;