﻿/*
 * POSTGRECR - MARC-HI CLIENT REGISTRY DATABASE SCHEMA FOR POSTGRESQL
 * VERSION: 2.0
 * AUTHOR: JUSTIN FYFE
 * DATE: JULY 12, 2012
 * FILES:
 *	POSTGRECR-DDL.SQL	- SQL CODE TO CREATE TABLES, INDECIES, VIEWS AND SEQUENCES
 *	POSTGRECR-FX.SQL	- SQL CODE TO CREATE SUPPORT PROCEDURES AND FUNCTIONS
 * DESCRIPTION:
 *	THIS FILE CREATES THE POSTGRESQL CLIENT REGISTRY STORED PROCEDURES AND FUNCTIONS
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

--CREATE LANGUAGE plpgsql;

-- @FUNCTION
-- GET DATABASE SCHEMA VERSION
--
-- RETURNS: THE MAJOR, MINOR AND RELEASE NUMBER OF THE DATABASE SCHEMA
CREATE OR REPLACE FUNCTION GET_SCH_VER() RETURNS VARCHAR AS
$$
BEGIN
	RETURN '0.8.0.0';
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A NEW CODE
--
-- RETURNS: THE IDENTIFIER OF THE CODE
CREATE OR REPLACE FUNCTION CRT_CODE
(
	CD_VAL_IN		IN VARCHAR(255),
	CD_DOMAIN_IN		IN VARCHAR(255),
	ORG_CNT_TYP_IN		IN VARCHAR(255),
	ORG_TEXT_IN		IN BYTEA,
	CD_VRSN_IN		IN VARCHAR(24),
	CD_QLFYS_CD_ID_IN	IN DECIMAL(20,0),
	CD_QLFYS_AS_IN		IN CHAR(1),
	CD_QLFYS_KV_ID_IN	IN VARCHAR(48),
	CAN_SHARE		IN BOOLEAN
) RETURNS DECIMAL
AS 
$$
DECLARE	
	CD_ID_VAL	DECIMAL(20,0);
BEGIN
	CD_ID_VAL := NULL;
	IF CAN_SHARE = TRUE THEN
		SELECT CD_ID INTO CD_ID_VAL FROM CD_TBL WHERE CD_VAL = CD_VAL_IN AND CD_DOMAIN = CD_DOMAIN_IN AND 
			(ORG_CNT_TYP_IN IS NULL AND ORG_CNT_TYP IS NULL OR ORG_CNT_TYP = ORG_CNT_TYP_IN) AND 
			(ORG_TEXT IS NULL AND ORG_TEXT_IN IS NULL OR ORG_TEXT = ORG_TEXT_IN) AND 
			(CD_VRSN IS NULL AND CD_VRSN_IN IS NULL OR CD_VRSN = CD_VRSN_IN);
	END IF;
	IF(CD_ID_VAL IS NULL) THEN
		CD_ID_VAL := NEXTVAL('cd_seq');
		INSERT INTO CD_TBL (CD_ID, CD_VAL, CD_DOMAIN, ORG_CNT_TYP, ORG_TEXT, CD_VRSN, CD_QLFYS, CD_QLFYS_AS, CD_QLFYS_KV_ID)
			VALUES (CD_ID_VAL, CD_VAL_IN, CD_DOMAIN_IN, ORG_CNT_TYP_IN, ORG_TEXT_IN, CD_VRSN_IN, CD_QLFYS_CD_ID_IN, CD_QLFYS_AS_IN, CD_QLFYS_KV_ID_IN);
	END IF;
	RETURN CD_ID_VAL;

END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A CODE
--
-- RETURNS: THE SPECIFIED CODE
CREATE OR REPLACE FUNCTION GET_CODE
(
	CD_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF CD_TBL AS 
$$
BEGIN
	RETURN QUERY SELECT * FROM CD_TBL WHERE CD_ID = CD_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION 
-- GET CODE QUALIFIERS
--
-- RETURNS: SPECIFIED CODE QUALIFIERS
CREATE OR REPLACE FUNCTION GET_CODE_QLFYS
(
	CD_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF CD_TBL AS
$$
BEGIN
	RETURN QUERY SELECT * FROM CD_TBL WHERE CD_QLFYS = CD_ID_IN;
END;
$$ LANGUAGE plpgsql;


-- @FUNCTION
-- CREATE A NEW NAME COMPONENT
-- 
-- RETURNS: THE ID OF THE NAME COMPONENT
CREATE OR REPLACE FUNCTION CRT_NAME_CMP
(
	NAME_VALUE_IN		VARCHAR(255),
	NAME_CLS_IN		DECIMAL(4),
	NAME_SET_ID_IN		DECIMAL(20,0)
) RETURNS DECIMAL
AS
$$
DECLARE
	NAME_CMP_ID_VAL	DECIMAL;
BEGIN
	NAME_CMP_ID_VAL := nextval('NAME_CMP_SEQ');
	INSERT INTO NAME_CMP_TBL (NAME_CMP_ID, NAME_CMP_CLS, NAME_CMP_VALUE, NAME_SET_ID)
		VALUES(NAME_CMP_ID_VAL, COALESCE(NAME_CLS_IN, 1), NAME_VALUE_IN, COALESCE(NAME_SET_ID_IN, NAME_CMP_ID_VAL));
	RETURN NAME_CMP_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A NAME SET ASSOCIATED WITH A PERSON
CREATE OR REPLACE FUNCTION CRT_PSN_NAME_SET
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	NAME_SET_USE_IN		IN VARCHAR(32)
) RETURNS DECIMAL
AS
$$
DECLARE
	PSN_NAME_SET_ID DECIMAL;
BEGIN
	PSN_NAME_SET_ID := nextval('NAME_CMP_SEQ');
	INSERT INTO PSN_NAME_SET_TBL (NAME_SET_ID, NAME_SET_USE, PSN_ID, EFFT_VRSN_ID) VALUES
		(PSN_NAME_SET_ID, NAME_SET_USE_IN, PSN_ID_IN, PSN_VRSN_ID_IN);
	RETURN PSN_NAME_SET_ID;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- OBSOLETE NAME SET ASSOCIATED WITH A PERSON
CREATE OR REPLACE FUNCTION OBSLT_PSN_NAME_SET
(
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	NAME_SET_ID_IN		IN DECIMAL(20,0)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_NAME_SET_TBL SET OBSLT_VRSN_ID = PSN_VRSN_ID_IN WHERE NAME_SET_ID = NAME_SET_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A NAME SET
--
-- RETURNS: A SET OF NAME_CMP_TBL RECORDS REPRESENTING THE SET
CREATE OR REPLACE FUNCTION GET_NAME_SET
(
	NAME_SET_ID_IN		IN DECIMAL(20)
) RETURNS SETOF NAME_CMP_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM NAME_CMP_TBL WHERE NAME_SET_ID = NAME_SET_ID_IN ORDER BY NAME_CMP_ID;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL NAME SETS FOR A SPECIFIC PERSON AT A SPECIFIC VERSION
CREATE OR REPLACE FUNCTION GET_PSN_NAME_SETS
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_NAME_SET_VW
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_NAME_SET_VW WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A NEW ADDRESS COMPONENT
-- 
-- RETURNS: THE ID OF THE ADDRESS COMPONENT
CREATE OR REPLACE FUNCTION CRT_ADDR_CMP
(
	ADDR_VALUE_IN		VARCHAR(255),
	ADDR_CLS_IN		DECIMAL(4),
	ADDR_SET_ID_IN		DECIMAL(20,0)
) RETURNS DECIMAL
AS
$$
DECLARE
	ADDR_CMP_ID_VAL	DECIMAL;
BEGIN
	ADDR_CMP_ID_VAL := nextval('ADDR_CMP_SEQ');
	INSERT INTO ADDR_CMP_TBL (ADDR_CMP_ID, ADDR_CMP_CLS, ADDR_CMP_VALUE, ADDR_SET_ID)
		VALUES(ADDR_CMP_ID_VAL, ADDR_CLS_IN, ADDR_VALUE_IN, COALESCE(ADDR_SET_ID_IN, ADDR_CMP_ID_VAL));
	RETURN ADDR_CMP_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A ADDRESS SET ASSOCIATED WITH A PERSON
CREATE OR REPLACE FUNCTION CRT_PSN_ADDR_SET
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	ADDR_SET_USE_IN		IN VARCHAR(32)
) RETURNS DECIMAL
AS
$$
DECLARE
	PSN_ADDR_SET_ID DECIMAL;
BEGIN
	PSN_ADDR_SET_ID := nextval('ADDR_CMP_SEQ');
	INSERT INTO PSN_ADDR_SET_TBL (ADDR_SET_ID, ADDR_SET_USE, PSN_ID, EFFT_VRSN_ID) VALUES
		(PSN_ADDR_SET_ID, ADDR_SET_USE_IN, PSN_ID_IN, PSN_VRSN_ID_IN);
	RETURN PSN_ADDR_SET_ID;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- OBSOLETE ADDRESS SET ASSOCIATED WITH A PERSON
CREATE OR REPLACE FUNCTION OBSLT_PSN_ADDR_SET
(
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	ADDR_SET_ID_IN		IN DECIMAL(20,0)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_ADDR_SET_TBL SET OBSLT_VRSN_ID = PSN_VRSN_ID_IN WHERE ADDR_SET_ID = ADDR_SET_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET THE CONTENTS OF AN ADDRESS SET
CREATE OR REPLACE FUNCTION GET_ADDR_SET
(
	ADDR_SET_ID_IN		IN DECIMAL(20)
) RETURNS SETOF ADDR_CMP_TBL
AS 
$$
BEGIN
	RETURN QUERY SELECT * FROM ADDR_CMP_TBL WHERE ADDR_SET_ID = ADDR_SET_ID_IN ORDER BY ADDR_CMP_ID;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL ADDRESS SETS FOR A SPECIFIC PERSON AT A SPECIFIC VERSION
CREATE OR REPLACE FUNCTION GET_PSN_ADDR_SETS
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_ADDR_SET_VW
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_ADDR_SET_VW WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A NEW TIMESTAMP 
--
-- RETURNS: THE ID OF THE TIMESTAMP RECORD
CREATE OR REPLACE FUNCTION CRT_TS
(
	TS_VALUE_IN		TIMESTAMPTZ,
	TS_PRECISION_IN		CHAR(1),
	TS_CLS_IN		CHAR(1),
	TS_SET_ID_IN		DECIMAL(20,0)
) RETURNS DECIMAL
AS
$$
DECLARE
	TS_ID_VAL	DECIMAL;
BEGIN
	TS_ID_VAL := nextval('TS_SEQ');
	INSERT INTO TS_TBL(TS_ID, TS_VALUE, TS_PRECISION, TS_CLS, TS_SET_ID)
		VALUES (TS_ID_VAL, TS_VALUE_IN, TS_PRECISION_IN, TS_CLS_IN, COALESCE(TS_SET_ID_IN, TS_ID_VAL));
	RETURN TS_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A TIMESTAMP AS A SET
CREATE OR REPLACE FUNCTION GET_TS_SET
(
	TS_SET_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF TS_TBL AS 
$$
BEGIN
	RETURN QUERY SELECT * FROM TS_TBL WHERE TS_SET_ID = TS_SET_ID_IN;
END;
$$ LANGUAGE plpgsql;

-- @REGION
-- CLIENT FUNCTIONS

-- @PROCEDURE
-- CREATE AN ALTERNATIVE IDENTIFIER FOR THE CLIENT
CREATE OR REPLACE FUNCTION CRT_PSN_ALT_ID
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	IS_HCN_IN		IN BOOLEAN,
	ID_PURP_IN		IN VARCHAR(10), 
	ID_DOMAIN_IN		IN VARCHAR(48),
	ID_VALUE_IN		IN VARCHAR(48)
) RETURNS VOID AS
$$
BEGIN
	INSERT INTO CLNT_ALT_ID_TBL (ID_DOMAIN, ID_VALUE, PSN_ID, EFFT_VRSN_ID, IS_HCN, ID_PURP)
		VALUES (ID_DOMAIN_IN, ID_VALUE_IN, PSN_ID_IN, PSN_VRSN_ID_IN, IS_HCN_IN, ID_PURP_IN);
	RETURN;
EXCEPTION
	WHEN unique_violation THEN
		RAISE NOTICE 'CR002: ALTERNATE IDENTIFIER ALREADY REGISTERED';
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- OBSOLETE ALTERNATE ID ASSOCIATED WITH A PERSON
CREATE OR REPLACE FUNCTION OBSLT_PSN_ALT_ID
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	ID_DOMAIN_IN		IN VARCHAR(256),
	ID_VALUE_IN		IN VARCHAR(256)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_ALT_ID_TBL SET OBSLT_VRSN_ID = PSN_VRSN_ID_IN WHERE ID_DOMAIN = ID_DOMAIN_IN AND ID_VALUE = ID_VALUE_IN AND PSN_ID = PSN_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALTERNATE IDENTIFIERS 
CREATE OR REPLACE FUNCTION GET_PSN_ALT_ID
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_ALT_ID_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_ALT_ID_TBL WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE CLIENT TELECOM DATA
CREATE OR REPLACE FUNCTION CRT_PSN_TEL
(
	PSN_ID_IN	IN DECIMAL(20,0),
	PSN_VRSN_ID_IN	IN DECIMAL(20,0),
	TELECOM_IN	IN VARCHAR(512),
	TELECOM_USE_IN	IN VARCHAR(32),
	TELECOM_CAP_IN	IN VARCHAR(32)
) RETURNS DECIMAL AS
$$
DECLARE
	PSN_TEL_NO	DECIMAL(20,0);
BEGIN
	PSN_TEL_NO := nextval('clnt_tel_seq');
	INSERT INTO CLNT_TEL_TBL (TEL_ID, TEL_VALUE, TEL_USE, TEL_CAP, PSN_ID, EFFT_VRSN_ID) VALUES
		(PSN_TEL_NO, TELECOM_IN, TELECOM_USE_IN, TELECOM_CAP_IN, PSN_ID_IN, PSN_VRSN_ID);

	RETURN CLNT_TEL_NO;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- OBSOLETE ADDRESS SET ASSOCIATED WITH A PERSON
CREATE OR REPLACE FUNCTION OBSLT_PSN_TEL
(
	PSN_ID_IN		IN DECIMAL(20),
	TEL_VALUE_IN		IN VARCHAR(256),
	TEL_USE_IN		IN VARCHAR(32),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_TEL_TBL SET OBSLT_VRSN_ID = PSN_VRSN_ID_IN WHERE TEL_VALUE = TEL_VALUE_IN AND TEL_USE = TEL_USE_IN AND PSN_ID = PSN_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET TELECOM DATA
CREATE OR REPLACE FUNCTION GET_PSN_TELS
(
	PSN_ID_IN		IN DECIMAL(20),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_TEL_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_TEL_TBL WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET MOST CURRENT VERSION OF PERSON DATA BASED ON THE ID
--
-- RETURNS: TABLE OF DATA 
CREATE OR REPLACE FUNCTION GET_PSN_CRNT_VRSN
(
	PSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_VRSN_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_VRSN_TBL WHERE PSN_ID = PSN_ID_IN ORDER BY PSN_VRSN_ID DESC LIMIT 1;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET SPECIFIC VERSION OF A PERSON
--
-- RETURNS: TABLE OF DATA 
CREATE OR REPLACE FUNCTION GET_PSN_VRSN
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_VRSN_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_VRSN_TBL WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID = PSN_VRSN_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A CLIENT BASED ON AN EXTERNAL IDENTIFIER
--
-- RETURNS: TABLE OF CLIENT DATA
CREATE OR REPLACE FUNCTION GET_PSN_EXTERN
(
	ID_DOMAIN_IN		IN VARCHAR(48),
	ID_VALUE_IN		IN VARCHAR(48)
) RETURNS SETOF PSN_VRSN_TBL AS
$$
BEGIN
	RETURN QUERY SELECT PSN_VRSN_TBL.* FROM PSN_VRSN_TBL NATURAL JOIN PSN_ALT_ID_TBL WHERE
		ID_DOMAIN = ID_DOMAIN_IN AND 
		ID_VALUE = ID_VALUE_IN
		ORDER BY PSN_VRSN_TBL.PSN_VRSN_ID DESC
		LIMIT 1
		;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A NEW PERSON IN THE DATABASE
-- 
-- RETURNS: THE CRID OF THE CLIENT
CREATE OR REPLACE FUNCTION CRT_PSN
(
	REG_VRSN_ID_IN	IN DECIMAL(20,0),
	STATUS_IN	IN VARCHAR(12),
	GNDR_CS_IN	IN CHAR(1),
	BRTH_TS_IN	IN DECIMAL,
	MB_ORD_IN	IN DECIMAL(2),
	RLGN_CD_ID_IN	IN DECIMAL(20,0)
) RETURNS TABLE
(
	PSN_ID		DECIMAL(20,0),
	PSN_VRSN_ID	DECIMAL(20,0)
)
AS
$$
DECLARE
	NEW_ID		DECIMAL;
	NEW_VRSN_ID	DECIMAL;
BEGIN
	NEW_ID := nextval('PSN_SEQ');
	NEW_VRSN_ID := nextval('PSN_VRSN_ID');

	-- INSERT CLIENT DATA
	INSERT INTO PSN_TBL (PSN_ID)
		VALUES (NEW_ID);

	-- INSERT VERSION
	INSERT INTO PSN_VRSN_TBL (PSN_VRSN_ID, PSN_ID, REG_VRSN_ID, STATUS, CRT_UTC, GNDR_CS, BRTH_TS, MB_ORD, RLGN_CD_ID)
		VALUES (NEW_VRSN_ID, NEW_ID, REG_VRSN_ID_IN, STATUS_IN, CURRENT_TIMESTAMP, GNDR_CS_IN, BRTH_TS_IN, MB_ORD_IN, RLGN_CD_ID_IN);
	
	-- RETURN SHRID
	RETURN QUERY SELECT NEW_ID, NEW_VRSN_ID;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET THE CURRENT PERSON VERSION
-- 
-- RETURNS: THE CURERNT VERSION ID OF THE SPECIFIED PERSON
CREATE OR REPLACE FUNCTION GET_PSN_CUR_VRSN_ID
(
	PSN_ID_IN	IN DECIMAL(20,0) -- THE ID FOR WHICH THE VERSION IS TO BE RETRIEVED
) RETURNS DECIMAL
AS
$$
BEGIN
	RETURN (SELECT PSN_VRSN_ID FROM GET_PSN_CRNT_VRSN(PSN_ID_IN));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A VERSION OF A PERSON RECORD
CREATE OR REPLACE FUNCTION CRT_PSN_VRSN
(
	PSN_ID_IN	IN DECIMAL(20,0),
	REG_VRSN_ID_IN	IN DECIMAL(20,0),
	STATUS_IN	IN VARCHAR(12),
	GNDR_CS_IN	IN CHAR(1),
	BRTH_TS_IN	IN DECIMAL,
	DCSD_TS_IN	IN DECIMAL,
	MB_ORD		DECIMAL(2),
	RLGN_CD_ID	DECIMAL(20,0)
) RETURNS DECIMAL
AS
$$
DECLARE
	NEW_VRSN_ID	DECIMAL;
	PSN_CUR_VRSN_ID DECIMAL;
BEGIN
	NEW_VRSN_ID := nextval('PSN_VRSN_SEQ');

	-- GET THE CURRENT VERSION IDENTIFIER
	SELECT GET_PSN_CUR_VRSN_ID(PSN_ID_IN) INTO PSN_CUR_VRSN_ID;

	-- SANITY CHECK
	IF PSN_CUR_VRSN_ID IS NULL THEN
		RAISE EXCEPTION 'CR001: CANNOT INSERT VERSION FOR NON-EXISTANT PSN';
	END IF;
	
	-- GET THE NEW VERSION ID
	NEW_VRSN_ID := nextval('HSR_SEQ');
	
	-- DUPLICATE THE CURRENT VERSION RECORD INTO THE NEW VERSION RECORD
	INSERT INTO PSN_VRSN_TBL 
		SELECT 
			NEW_VRSN_ID,
			PSN_ID_IN,
			PSN_CUR_VRSN_ID,
			REG_VRSN_ID_IN,
			COALESCE(STATUS_IN, STATUS),
			CURRENT_TIMESTAMP,
			NULL,
			COALESCE(GNDR_CS_IN, GNDR_CS),
			COALESCE(BRTH_TS_IN, BRTH_TS),
			COALESCE(DCSD_TS_IN, DCSD_TS),
			COALESCE(MB_ORD_IN, MB_ORD),
			COALESCE(RLGN_CD_ID_IN, RLGN_CD_ID)
		FROM PSN_VRSN_TBL WHERE
			PSN_VRSN_ID = PSN_CUR_VRSN_ID;

	-- OBSOLETE THE OLD VERSION
	UPDATE PSN_VRSN_TBL SET OBSLT_UTC = CURRENT_TIMESTAMP
		WHERE HSR_VRSN_ID = HSR_CUR_VRSN_ID;

	-- RETURN NEW VERSION ID
	RETURN NEW_VRSN_ID;		

END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- DELETE A PERSON
CREATE OR REPLACE FUNCTION DEL_PSN
(
	PSN_ID_IN	IN DECIMAL(20,0),
	REG_VRSN_ID_IN	IN DECIMAL(20,0)
) RETURNS VOID AS
$$
BEGIN
	SELECT CRT_PSN_VRSN(PSN_ID_IN, REG_VRSN_ID_IN, 'Nullified', NULL, NULL, NULL, NULL, NULL);
END;
$$ LANGUAGE plpgsql;
	
-- @PROCEDURE
-- LINK TWO CLIENTS TOGETHER
CREATE OR REPLACE FUNCTION CRT_PSN_RLTNSHP
(
	SRC_PSN_ID_IN		IN DECIMAL(20),
	TRG_PSN_ID_IN		IN DECIMAL(20),
	KIND_IN			IN VARCHAR(10)
) RETURNS DECIMAL AS 
$$
DECLARE
	RLTNSHP_ID_ID	DECIMAL;
	SRC_VRSN_ID	DECIMAL;
BEGIN
	-- IS THERE AN ACTIVE RELATIONSHIP FOR THIS KIND ALREADY? 
	SELECT RLTNSHP_ID INTO RLTNSHP_ID_ID FROM PSN_RLTNSHP_TBL WHERE 
		SRC_PSN_ID = SRC_PSN_ID_IN AND
		TRG_PSN_ID = TRG_PSN_ID_IN AND
		KIND_CS = KIND_IN AND
		OBSLT_VRSN_ID IS NULL;

	-- YES? 
	IF(RLTNSHP_ID_ID IS NOT NULL) THEN
		RAISE EXCEPTION 'CR0004: CLIENTS ARE ALREADY RELATED IN THIS MANNER';
	ELSE -- NO
		SELECT GET_PSN_CUR_VRSN_ID(SRC_PSN_ID_IN) INTO SRC_VRSN_ID;
		RLTNSHP_ID_ID := nextval('PSN_RLTNSHP_SEQ');
		INSERT INTO PSN_RLTNSHP_TBL (RLTNSHP_ID, SRC_PSN_ID, TRG_PSN_ID, KIND_CS, EFFT_VRSN_ID) VALUES
			(RLTNSHP_ID_ID, SRC_PSN_ID_IN, TRG_PSN_ID_IN, KIND_IN, SRC_VRSN_ID);
	END IF;

	RETURN RTLNSHP_ID_ID;
END
$$ LANGUAGE plpgsql;

--@FUNCTION
-- GET PERSONAL RELATIONSHIP BY PERSONAL RELATIONSHIP IDENTIFIER
CREATE OR REPLACE FUNCTION GET_PSN_RLTNSHPS
(
	PSN_ID_IN		IN DECIMAL(20),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_RLTNSHP_TBL
AS
$$
BEGIN
	IF PSN_VSN_ID_IN IS NULL THEN
		SELECT GET_PSN_CUR_VRSN_ID(PSN_ID_IN) INTO PSN_VRSN_ID_IN;
	END IF;
	RETURN QUERY SELECT * FROM PSN_RLTNSHP_TBL WHERE PSN_ID = PSN_ID_ID AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION 
-- OBSOLETE A RELATIONSHIP
CREATE OR REPLACE FUNCTION OBSLT_PSN_RLTNSHP
(
	SRC_PSN_ID_IN		IN DECIMAL(20),
	SRC_PSN_VRSN_ID_IN	IN DECIMAL(20,0),
	TRG_PSN_ID_IN		IN DECIMAL(20,0),
	KIND_CS_IN		IN VARCHAR(10)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_RLTNSHP_TBL SET OBSLT_VRSN_ID = SRC_PSN_VRSN_ID_IN WHERE SRC_PSN_ID = SRC_PSN_ID_IN AND TRG_PSN_ID = TRG_PSN_ID_IN AND 
		KIND_CS = KIND_CS_IN;
END
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- CREATE A RACE CODE
CREATE OR REPLACE FUNCTION CRT_PSN_RACE
(
	PSN_ID_IN		IN DECIMAL(20),
	PSN_VRSN_ID_IN		IN DECIMAL(20),
	RACE_CD_ID_IN		IN DECIMAL(20)
) RETURNS VOID AS 
$$
BEGIN
	INSERT INTO PSN_RACE_TBL (PSN_ID, RACE_CD_ID, EFFT_VRSN_ID) VALUES
		(PSN_ID_IN, RACE_CD_ID_IN, PSN_VRSN_ID_IN);
	RETURN;
END
$$ LANGUAGE plpgsql;

--@FUNCTION
-- GET PERSON RACES
CREATE OR REPLACE FUNCTION GET_PSN_RACES
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_RACE_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_RACE_TBL WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION 
-- OBSOLETE A PERSON RACE
CREATE OR REPLACE FUNCTION OBSLT_PSN_RACE
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	RACE_CD_ID_IN		IN DECIMAL(20,0)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_RACE_TBL SET OBSLT_VRSN_ID = PSN_VRSN_ID_IN WHERE PSN_ID = PSN_ID_IN AND RACE_CD_ID = RACE_CD_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- CREATE A LANGUAGE CODE
CREATE OR REPLACE FUNCTION CRT_PSN_LANG
(
	PSN_ID_IN		IN DECIMAL(20),
	PSN_VRSN_ID_IN		IN DECIMAL(20),
	LANG_CS_IN		IN VARCHAR(3), 
	MODE_CS_IN		IN DECIMAL(1)
) RETURNS DECIMAL AS 
$$
DECLARE
	LANG_ID_ID	DECIMAL;
BEGIN
	LANG_ID_ID = nextval('PSN_LANG_SEQ');
	INSERT INTO PSN_LANG_TBL (LANG_ID, LANG_CS, MODE_CS, PSN_ID, EFFT_VRSN_ID) VALUES
		(LANG_ID_ID, LANG_CS_IN, MODE_CS_IN, PSN_ID_IN, PSN_VRSN_ID_IN);
	RETURN LANG_ID_ID;
END
$$ LANGUAGE plpgsql;

--@FUNCTION
-- GET PERSONS LANGUAGE
CREATE OR REPLACE FUNCTION GET_PSN_LANGS
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF PSN_LANG_TBL
AS
$$
BEGIN
	RETURN QUERY SELECT * FROM PSN_LANG_TBL WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID_IN BETWEEN EFFT_VRSN_ID AND COALESCE(OBSLT_VRSN_ID, (SELECT max_value FROM PSN_VRSN_SEQ));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION 
-- OBSOLETE A RELATIONSHIP
CREATE OR REPLACE FUNCTION OBSLT_PSN_LANG
(
	PSN_ID_IN		IN DECIMAL(20,0),
	PSN_VRSN_ID_IN		IN DECIMAL(20,0),
	LANG_CS_IN		IN VARCHAR(3),
	MODE_CS_IN		IN CHAR(1)
) RETURNS VOID 
AS
$$
BEGIN
	UPDATE PSN_LANG_TBL SET OBSLT_VRSN_ID = PSN_VRSN_ID WHERE
		PSN_ID = PSN_ID_IN AND LANG_CS = LANG_CS_IN AND MODE_CS = MODE_CS_IN;
END
$$ LANGUAGE plpgsql;
-- END CLIENT FUNCTIONS
-- @ENDREGION

-- @REGION
-- HEALTHCARE PARTICIPANT FUNCTIONS

-- @FUNCTION
-- CREATE A HEALTHCARE PARTICIPANT ORGANIZATION
-- 
-- RETURNS: THE ID OF THE HEALTHCARE PARTICIPANT
CREATE OR REPLACE FUNCTION CRT_HC_PTCPT_ORG
(
	PTCPT_NAME_IN		IN VARCHAR(255),
	PTCPT_ADDR_SET_ID_IN	IN DECIMAL(20,0),
	PTCPT_WORK_TEL_IN	IN VARCHAR(255),
	PTCPT_TYP_CD_ID_IN	IN DECIMAL(20,0)

) RETURNS DECIMAL
AS
$$
DECLARE
	HC_PTCPT_ID_VAL		DECIMAL;
	HC_PTCPT_NAME_SET_ID	DECIMAL;

BEGIN
	HC_PTCPT_ID_VAL := nextval('HC_PTCPT_SEQ');
	HC_PTCPT_NAME_SET_ID := nextval('NAME_CMP_SEQ');

	-- INSERT THE NAME SET
	PERFORM CRT_NAME_CMP(PTCPT_NAME_IN, 1, HC_PTCPT_NAME_SET_ID);

	-- INSERT THE PARTICIPANT
	INSERT INTO HC_PTCPT_TBL (PTCPT_ID, PTCPT_CLS_CS, PTCPT_ADDR_SET_ID, PTCPT_NAME_SET_ID, PTCPT_TYP_CD_ID)
		VALUES (HC_PTCPT_ID_VAL, 'ORG', PTCPT_ADDR_SET_ID_IN, HC_PTCPT_NAME_SET_ID, PTCPT_TYP_CD_ID_IN);

	-- INSERT THE TELECOM
	IF PTCPT_WORK_TEL_IN IS NOT NULL THEN 
		INSERT INTO HC_PTCPT_TEL_TBL (TEL_USE, PTCPT_ID, TEL_VALUE)
			VALUES ('W', HC_PTCPT_ID_VAL, PTCPT_WORK_TEL_IN);
	END IF;
	
	RETURN HC_PTCPT_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A HEALTHCARE PARTICIPANT PERSON
-- 
-- RETURNS: THE ID OF THE HEALTHCARE PARTICIPANT
CREATE OR REPLACE FUNCTION CRT_HC_PTCPT_PSN
(
	PTCPT_NAME_SET_ID_IN	IN DECIMAL(20,0),
	PTCPT_ADDR_SET_ID_IN	IN DECIMAL(20,0),
	PTCPT_TEL_IN		IN VARCHAR(255),
	PTCPT_TYP_CD_ID_IN	IN DECIMAL(20,0)
) RETURNS DECIMAL
AS
$$
DECLARE
	HC_PTCPT_ID_VAL		DECIMAL;
BEGIN
	HC_PTCPT_ID_VAL := nextval('HC_PTCPT_SEQ');

	-- INSERT THE PARTICIPANT
	INSERT INTO HC_PTCPT_TBL (PTCPT_ID, PTCPT_CLS_CS, PTCPT_ADDR_SET_ID, PTCPT_NAME_SET_ID, PTCPT_TYP_CD_ID)
		VALUES (HC_PTCPT_ID_VAL, 'PSN', PTCPT_ADDR_SET_ID_IN, PTCPT_NAME_SET_ID_IN, PTCPT_TYP_CD_ID_IN);
		
	-- INSERT THE TELECOM
	IF PTCPT_TEL_IN != NULL THEN 
		INSERT INTO HC_PTCPT_TEL_TBL (TEL_USE, PTCPT_ID, TEL_VALUE)
			VALUES ('W', HC_PTCPT_ID_VAL, PTCPT_WORK_TEL_IN);
	END IF;
	
	RETURN HC_PTCPT_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- ADD A TELECOMMUNICATIONS ADDRESS TO A CLIENT
CREATE OR REPLACE FUNCTION ADD_HC_PTCPT_TEL
(
	PTCPT_ID_IN	IN DECIMAL(20,0),
	TEL_VALUE_IN	IN VARCHAR(255),
	TEL_USE_IN	IN VARCHAR(4)
) RETURNS VOID AS 
$$
BEGIN
	INSERT INTO HC_PTCPT_TEL_TBL (TEL_USE, PTCPT_ID, TEL_VALUE)
		VALUES (TEL_USE_IN, PTCPT_ID_IN, TEL_VALUE_IN);

	RETURN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL THE TELECOMMUNICATIONS ADDRESSES FOR A PROVIDER
CREATE OR REPLACE FUNCTION GET_HC_PTCPT_TEL
(
	PTCPT_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF HC_PTCPT_TEL_TBL AS 
$$
BEGIN
	RETURN QUERY SELECT * FROM HC_PTCPT_TEL_TBL WHERE PTCPT_ID = PTCPT_ID_IN;
END
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- LINKS A HEALTHCARE PARTICIPANT RECORD TO A HEALTH SERVICE RECORD
CREATE OR REPLACE FUNCTION LINK_HC_PTCPT
(
	HSR_ID_IN		IN DECIMAL(20,0),
	PTCPT_ID_IN		IN DECIMAL(20,0),
	PTCPT_CLS_IN		IN DECIMAL(6),
	PTCPT_REP_ORG_ID_IN	IN DECIMAL(20,0)	
) RETURNS VOID AS
$$
BEGIN
	INSERT INTO HSR_HC_PTCPT_TBL (HSR_ID, PTCPT_ID, PTCPT_CLS, PTCPT_REP_ORG_ID)
		VALUES (HSR_ID_IN, PTCPT_ID_IN, PTCPT_CLS_IN, PTCPT_REP_ORG_ID_IN);

	RETURN;
EXCEPTION 
	WHEN unique_violation THEN
		RAISE NOTICE 'CR003: ACTOR ALREADY PARTICIPATES IN THIS EVENT IN THIS ROLE';
END
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- LINKS A HEALTHCARE PARTICIPANT RECORD TO A HEALTH SERVICE RECORD
CREATE OR REPLACE FUNCTION ADD_LINK_HC_PTCPT_ORIG_ID
(
	HSR_ID_IN		IN DECIMAL(20,0),
	PTCPT_ID_IN		IN DECIMAL(20,0),
	PTCPT_CLS_IN		IN DECIMAL(6),
	ORIG_ID_DOMAIN_IN	IN VARCHAR(48),
	ORIG_ID_IN		IN VARCHAR(48),
	LICENSE_IND_IN		IN BOOLEAN
) RETURNS VOID AS
$$
BEGIN
	
	INSERT INTO HSR_HC_PTCPT_ORIG_ID_TBL (HSR_ID, PTCPT_ID, PTCPT_CLS, ORIG_ID_DOMAIN, ORIG_ID, LICENSE_IND)
		VALUES (HSR_ID_IN, PTCPT_ID_IN, PTCPT_CLS_IN, ORIG_ID_DOMAIN_IN, ORIG_ID_IN, LICENSE_IND_IN);

	RETURN;
EXCEPTION 
	WHEN unique_violation THEN
		RETURN;
END
$$ LANGUAGE plpgsql;


-- @PROCEDURE
-- UNLINK A HEALTHCARE PARTICIPANT RECORD FROM A HEALTH SERVICE RECORD
CREATE OR REPLACE FUNCTION UNLINK_HC_PTCPT
(
	HSR_ID_IN	IN DECIMAL(20,0),
	PTCPT_ID_IN	IN DECIMAL(20,0),
	PTCPT_CLS_IN	IN CHAR(6)
) RETURNS VOID AS
$$
BEGIN
	
	DELETE FROM HSR_HC_PTCPT_TBL 
		WHERE
			HSR_ID = HSR_ID_IN AND
			PTCPT_ID = PTCPT_ID_IN AND
			PTCPT_CLS = PTCPT_CLS_IN;

	RETURN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A HEALTHCARE PARTICIPANT BASED ON THE SHRID
CREATE OR REPLACE FUNCTION GET_HC_PTCPT
(
	PTCPT_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF HC_PTCPT_TBL AS 
$$
BEGIN
	RETURN QUERY SELECT * FROM HC_PTCPT_TBL WHERE PTCPT_ID = PTCPT_ID_IN;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A HEALTHCARE PARTICIPANT BASED ON AN EXTERNAL IDENTIFIER
CREATE OR REPLACE FUNCTION GET_HC_PTCPT_EXTERN
(
	PTCPT_ID_DOMAIN_IN	IN VARCHAR(48),
	PTCPT_ID_IN		IN VARCHAR(48)
) RETURNS SETOF HC_PTCPT_TBL AS
$$
DECLARE
	PTCPT_SHRID	DECIMAL;
BEGIN
	-- GET THE PARTICIPANT SHRID
	SELECT PTCPT_ID INTO PTCPT_SHRID FROM HC_PTCPT_ALT_ID_TBL
		WHERE ALT_ID_DOMAIN = PTCPT_ID_DOMAIN_IN AND
			ALT_ID = PTCPT_ID_IN;

	-- RETURN THE CLIENT DETAILS
	RETURN QUERY SELECT * FROM GET_HC_PTCPT(PTCPT_SHRID);
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL OF THE HEALTHCARE PARTICIPANTS LINKED TO THE CURRENT VERSION OF A HEALTH SERVICES EVENT
CREATE OR REPLACE FUNCTION GET_HSR_PTCPT
(
	HSR_ID_IN	IN DECIMAL(20,0), -- THE ID OF THE HSR EVENT
	PTCPT_ID_IN	IN DECIMAL(20,0), -- ID OF THE HC PARTICIPANT
	PTCPT_CLS_IN	IN DECIMAL(8,0) -- CLASSIFICATION OF THE PARTICIPATION
) RETURNS SETOF HSR_HC_PTCPT_VW
AS
$$
BEGIN
	-- GET THE CLIENTS ASSOCIATED WITH THIS
	RETURN QUERY SELECT * FROM HSR_HC_PTCPT_VW WHERE HSR_ID = HSR_ID_IN AND PTCPT_ID_IN = PTCPT_ID AND PTCPT_CLS_IN = PTCPT_CLS;
END;
$$ LANGUAGE plpgsql;


-- @PROCEDURE
-- CREATE AN ALTERNATIVE IDENTIFIER FOR THE CLIENT
CREATE OR REPLACE FUNCTION CRT_PTCPT_ALT_ID
(
	PTCPT_ID_IN		IN DECIMAL(20,0),
	ALT_ID_DOMAIN_IN	IN VARCHAR(48),
	ALT_ID_IN		IN VARCHAR(48)
) RETURNS VOID AS
$$
DECLARE 
	EXCEPTION_TEXT	TEXT;
BEGIN
	INSERT INTO HC_PTCPT_ALT_ID_TBL (ALT_ID_DOMAIN, PTCPT_ID, ALT_ID)
		VALUES (ALT_ID_DOMAIN_IN, PTCPT_ID_IN, ALT_ID_IN);
	RETURN;
EXCEPTION
	WHEN unique_violation THEN
		EXCEPTION_TEXT := 'CR002: ALTERNATE IDENTIFIER IN DOMAIN ' || ALT_ID_DOMAIN_IN || ' ALREADY REGISTERED';
		RAISE NOTICE '%', EXCEPTION_TEXT;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL ALTERNATE IDENTIFIERS FOR A HEALTHCARE PARTICIPANT
CREATE OR REPLACE FUNCTION GET_PTCPT_ALT_ID
(
	PTCPT_ID_IN	IN DECIMAL(20)
) RETURNS SETOF HC_PTCPT_ALT_ID_TBL AS
$$
BEGIN
	RETURN QUERY SELECT * FROM HC_PTCPT_ALT_ID_TBL WHERE PTCPT_ID = PTCPT_ID_IN;
END;
$$ LANGUAGE plpgsql;

-- END HEALTHCARE PARTICIPANT FUNCTIONS
-- @ENDREGION 

-- @REGION 
-- SERVICE DELIVERY LOCATION FUNCTIONS



-- @FUNCTION
-- CREATE A SERVICE DELIVERY LOCATION
-- 
-- RETURNS: THE ID OF THE SERVICE DELIVERY LOCATION
CREATE OR REPLACE FUNCTION CRT_SDL
(
	SDL_NAME_IN		IN VARCHAR(255), -- NAME 
	SDL_ADDR_SET_ID_IN	IN DECIMAL(20,0),
	SDL_TYP_CD_ID_IN	IN DECIMAL(20,0)
) RETURNS DECIMAL
AS
$$
DECLARE
	SDL_ID_VAL		DECIMAL;
BEGIN
	SDL_ID_VAL := nextval('SDL_SEQ');

	-- INSERT THE SDL
	INSERT INTO SDL_TBL (SDL_ID, SDL_NAME, SDL_ADDR_SET_ID, SDL_TYP_CD_ID)
		VALUES (SDL_ID_VAL, SDL_NAME_IN, SDL_ADDR_SET_ID_IN, SDL_TYP_CD_ID_IN);

	RETURN SDL_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- PROCEDURE
-- UPDATES A SERVICE DELIVERY LOCATION REGISTRY RECORD WITH NEW DATA
CREATE OR REPLACE FUNCTION UPD_SDL
(
	SDL_ID_IN		IN DECIMAL(20,0), -- ID OF THE SERVICE DELIVERY LOCATION
	SDL_ADDR_SET_ID_IN	IN DECIMAL(20,0), -- THE NEW IDENTIFIER OF THE ADDRESS OF THE SDL
	SDL_TYP_CD_ID_IN	IN DECIMAL(20,0) -- THE NEW TYPE OF SDL
) RETURNS VOID AS 
$$
BEGIN

	-- PERFORM UPDATE
	UPDATE SDL_TBL SET SDL_ADDR_SET_ID = COALESCE(SDL_ADDR_SET_ID_IN, SDL_ADDR_SET_ID), 
		SDL_TYP_CD_ID = COALESCE(SDL_TYP_CD_ID_IN, SDL_TYP_CD_ID)
	WHERE
		SDL_ID = SDL_ID_IN;

	RETURN;
END;
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- LINKS A SERVICE DELIVERY LOCATION RECORD TO A HEALTH SERVICE RECORD
CREATE OR REPLACE FUNCTION LINK_SDL
(
	HSR_ID_IN		IN DECIMAL(20,0),
	SDL_ID_IN		IN DECIMAL(20,0),
	SDL_CLS_IN		IN DECIMAL(6)
) RETURNS VOID AS
$$

BEGIN
	
	INSERT INTO HSR_SDL_TBL (HSR_ID, SDL_ID, SDL_CLS)
		VALUES (HSR_ID_IN, SDL_ID_IN, SDL_CLS_IN);

	RETURN;
EXCEPTION
	WHEN unique_violation THEN
		RAISE NOTICE 'CR003: ACTOR ALREADY PARTICIPATES IN THIS EVENT IN THIS ROLE';
END
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- UNLINK A SERVICE DELIVERY LOCATION RECORD FROM A HEALTH SERVICE RECORD
CREATE OR REPLACE FUNCTION UNLINK_SDL
(
	HSR_ID_IN	IN DECIMAL(20,0),
	SDL_ID_IN	IN DECIMAL(20,0),
	SDL_CLS_IN	IN CHAR(6)
) RETURNS VOID AS
$$
BEGIN
	DELETE FROM HSR_SDL_TBL 
		WHERE
			HSR_ID = HSR_ID_IN AND
			SDL_ID = SDL_ID_IN AND
			SDL_CLS = SDL_CLS_IN;

	RETURN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A SERVICE DELIVERY LOCATION BASED ON THE SHRID
CREATE OR REPLACE FUNCTION GET_SDL
(
	SDL_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF SDL_TBL AS 
$$
BEGIN
	RETURN QUERY SELECT * FROM SDL_TBL WHERE SDL_ID = SDL_ID_IN;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET A SERVICE DELIVERY LOCATION BASED ON AN EXTERNAL IDENTIFIER
CREATE OR REPLACE FUNCTION GET_SDL_EXTERN
(
	SDL_ID_DOMAIN_IN	IN VARCHAR(48),
	SDL_ID_IN		IN VARCHAR(48)
) RETURNS SETOF SDL_TBL AS
$$
DECLARE
	SDL_SHRID	DECIMAL;
BEGIN
	-- GET THE PARTICIPANT SHRID
	SELECT SDL_ID INTO SDL_SHRID FROM SDL_ALT_ID_TBL
		WHERE ALT_ID_DOMAIN = SDL_ID_DOMAIN_IN AND
			ALT_ID = SDL_ID_IN;

	-- RETURN THE CLIENT DETAILS
	RETURN QUERY SELECT * FROM GET_SDL(SDL_SHRID);
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL OF THE SERVICE DELIVERY LOCATIONS LINKED TO THE CURRENT VERSION OF A HEALTH SERVICES EVENT
CREATE OR REPLACE FUNCTION GET_HSR_SDLS
(
	HSR_ID_IN	IN DECIMAL(20,0) -- THE ID OF THE HSR EVENT
) RETURNS SETOF HSR_SDL_VW
AS
$$
BEGIN

	-- GET THE CLIENTS ASSOCIATED WITH THIS
	RETURN QUERY SELECT * FROM HSR_SDL_VW WHERE HSR_ID = HSR_ID_IN;
END;
$$ LANGUAGE plpgsql;

-- @PROCEDURE
-- CREATE AN ALTERNATIVE IDENTIFIER FOR THE SERVICE DELIVERY LOCATION
CREATE OR REPLACE FUNCTION CRT_SDL_ALT_ID
(
	SDL_ID_IN		IN DECIMAL(20,0),
	ALT_ID_DOMAIN_IN	IN VARCHAR(48),
	ALT_ID_IN		IN VARCHAR(48)
) RETURNS VOID AS
$$
BEGIN
	INSERT INTO SDL_ALT_ID_TBL (ALT_ID_DOMAIN, SDL_ID, ALT_ID)
		VALUES (ALT_ID_DOMAIN_IN, SDL_ID_IN, ALT_ID_IN);
	RETURN;
EXCEPTION
	WHEN unique_violation THEN
		RAISE NOTICE 'CR002: ALTERNATIVE IDENTIFIER ALREADY REGISTERED';
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET SDL ALTERNATIVE IDENTIFIERS
--
-- RETURNS: SET OF SDL_ALT_ID_TBL REPRESENTING THE ALTERNATE IDENTIFIERS FOR THE SPECIFIED SDL
CREATE OR REPLACE FUNCTION GET_SDL_ALT_ID
(
	SDL_ID_IN		IN DECIMAL(20,0)
) RETURNS SETOF SDL_ALT_ID_TBL AS
$$
BEGIN
	RETURN QUERY SELECT * FROM SDL_ALT_ID_TBL WHERE SDL_ID = SDL_ID_IN;
END
$$ LANGUAGE plpgsql;

-- END SERVICE DELIVERY LOCATION FUNCTIONS
-- @ENDREGION

-- @FUNCTION
-- CREATE A NEW HEALTH SERVICE RECORD
--
-- PURPOSE: CREATES THE HSR RECORD AND A PRIMARY VERSION FOR THE HSR 
--
-- RETURNS: THE ID OF THE HSR RECORD VERSION
CREATE OR REPLACE FUNCTION CRT_HSR
(
	HSR_CLS_IN		IN DECIMAL(4,0),
	EVT_TYP_CD_ID_IN	IN DECIMAL(20,0),
	REFUTED_IND_IN		IN BOOLEAN,
	EFFT_TS_SET_ID_IN	IN DECIMAL(20,0),
	STATUS_CS_IN		IN VARCHAR(10),
	AUT_UTC_IN		IN TIMESTAMPTZ,
	LANG_CS_IN		IN VARCHAR(10)
) RETURNS TABLE(
	VRSN_ID DECIMAL(20,0),
	ID  DECIMAL(20,0)
)
AS 
$$
DECLARE
	HSR_ID_VAL 	DECIMAL;
	HSR_VRSN_ID_VAL	DECIMAL;
BEGIN
	HSR_ID_VAL := nextval('HSR_SEQ');
	HSR_VRSN_ID_VAL := nextval('HSR_SEQ');
	INSERT INTO HSR_TBL (HSR_ID, HSR_CLS) VALUES (HSR_ID_VAL, HSR_CLS_IN);
	INSERT INTO HSR_VRSN_TBL (HSR_VRSN_ID, AUT_UTC, HSR_ID, EVT_TYP_CD_ID, REFUTED_IND, EFFT_TS_SET_ID, STATUS_CS, LANG_CS)
		VALUES (HSR_VRSN_ID_VAL, AUT_UTC_IN, HSR_ID_VAL, EVT_TYP_CD_ID_IN, REFUTED_IND_IN, EFFT_TS_SET_ID_IN, STATUS_CS_IN, LANG_CS_IN);
	RETURN QUERY SELECT HSR_VRSN_ID_VAL, HSR_ID_VAL;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- REVOKE THE HEALTH SERVICE EVENT
-- 
-- PURPOSE: REVOKES (OR OBSOLETES) THE HEALTH SERVICE RECORD
-- 
-- RETURNS: THE NEWEST VERSION ID OF THE HEALTH SERVICE EVENT
CREATE OR REPLACE FUNCTION DEL_HSR
(
	HSR_ID_IN	IN DECIMAL(20,0)
) RETURNS DECIMAL AS
$$
BEGIN
	RETURN (SELECT CRT_HSR_VRSN(HSR_ID_IN, NULL, NULL, NULL, 'Nullfied', NULL));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET THE CURRENT HSR VERSION
-- 
-- RETURNS: THE CURERNT VERSION ID OF THE SPECIFIED HSR_ID
CREATE OR REPLACE FUNCTION GET_CUR_VRSN_ID
(
	HSR_ID_IN	IN DECIMAL(20,0) -- THE HSR ID FOR WHICH THE VERSION IS TO BE RETRIEVED
) RETURNS DECIMAL
AS
$$
BEGIN
	RETURN (SELECT HSR_VRSN_ID FROM GET_HSR_CRNT_VRSN(HSR_ID_IN));
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A NEW HEALTH SERVICE RECORD VERSION
-- 
-- PURPOSE: INSERTS A NEW HEALTH SERVICE RECORD VERSION INTO THE HSR_VRSN TABLE, DUPLICATES THE VERSION
--
-- RETURNS: THE IDENTIFIER OF THE NEW VERSION
CREATE OR REPLACE FUNCTION CRT_HSR_VRSN
(
	HSR_ID_IN		IN DECIMAL(20,0), -- THE HSR ID FOR WHICH THE NEW VERSION IS CREATED
	EVT_TYP_CD_ID_IN	IN DECIMAL(20,0), 
	REFUTED_IND_IN		IN BOOLEAN,
	EFFT_TS_SET_ID_IN	IN DECIMAL(20,0),
	STATUS_CS_IN		IN VARCHAR(10),
	AUT_UTC_IN		IN TIMESTAMPTZ,
	LANG_CS_IN		IN VARCHAR(10)
) RETURNS DECIMAL AS
$$
DECLARE
	HSR_CUR_VRSN_ID	DECIMAL;
	NEW_VRSN_ID	DECIMAL;
BEGIN
	-- GET THE CURRENT VERSION IDENTIFIER
	SELECT GET_CUR_VRSN_ID(HSR_ID_IN) INTO HSR_CUR_VRSN_ID;

	-- SANITY CHECK
	IF HSR_CUR_VRSN_ID IS NULL THEN
		RAISE EXCEPTION 'CR001: CANNOT INSERT VERSION FOR NON-EXISTANT HSR';
	END IF;
	
	-- GET THE NEW VERSION ID
	NEW_VRSN_ID := nextval('HSR_SEQ');
	
	-- DUPLICATE THE CURRENT VERSION RECORD INTO THE NEW VERSION RECORD
	INSERT INTO HSR_VRSN_TBL 
		SELECT 
			NEW_VRSN_ID,
			COALESCE(EVT_TYP_CD_ID_IN, EVT_TYP_CD_ID),
			CURRENT_TIMESTAMP, 
			COALESCE(AUT_UTC_IN, AUT_UTC),
			NULL,
			COALESCE(REFUTED_IND_IN, REFUTED_IND),
			COALESCE(EFFT_TS_SET_ID_IN, EFFT_TS_SET_ID),
			COALESCE(STATUS_CS_IN, STATUS_CS),
			COALESCE(LANG_CS_IN, LANG_CS),
			HSR_ID_IN,
			HSR_CUR_VRSN_ID
		FROM HSR_VRSN_TBL WHERE
			HSR_VRSN_ID = HSR_CUR_VRSN_ID;

	-- OBSOLETE THE OLD VERSION
	UPDATE HSR_VRSN_TBL SET OBSLT_UTC = CURRENT_TIMESTAMP
		WHERE HSR_VRSN_ID = HSR_CUR_VRSN_ID;

	-- RETURN NEW VERSION ID
	RETURN NEW_VRSN_ID;		
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET THE CURRENT VERSION OF AN HSR EVENT
-- 
-- RETURNS: A SET OF HSR_LTST_CRNT_VRSN_VW RECORDS REPRESENTING THE CURRENT VERSION
CREATE OR REPLACE FUNCTION GET_HSR_CRNT_VRSN
(
	HSR_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF HSR_LTST_CRNT_VRSN_VW AS
$$
BEGIN
	RETURN QUERY SELECT DISTINCT ON (hsr_tbl.hsr_id) hsr_vrsn_tbl.hsr_vrsn_id, hsr_vrsn_tbl.evt_typ_cd_id, hsr_vrsn_tbl.crtn_utc, hsr_vrsn_tbl.aut_utc, hsr_vrsn_tbl.obslt_utc, hsr_vrsn_tbl.refuted_ind, hsr_vrsn_tbl.efft_ts_set_id, hsr_vrsn_tbl.status_cs, hsr_vrsn_tbl.lang_cs, hsr_vrsn_tbl.hsr_id, hsr_vrsn_tbl.rplc_vrsn_id, hsr_tbl.hsr_cls
	   FROM hsr_vrsn_tbl 
	   INNER JOIN hsr_tbl USING (hsr_id)
	   WHERE hsr_tbl.hsr_id = hsr_id_in AND
	   obslt_utc IS NULL
	  ORDER BY hsr_tbl.hsr_id, hsr_vrsn_tbl.hsr_vrsn_id, hsr_vrsn_tbl.crtn_utc DESC;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL VERSIONS OF AN HSR EVENT
--
-- RETURNS: A SET OF HSR_VRSN_VW RECORDS REPRESENTING THE VERSIONS OF THE SPECIFIED HSR EVENT
CREATE OR REPLACE FUNCTION GET_HSR_VRSN
(
	HSR_ID_IN	IN DECIMAL(20,0),
	HSR_VRSN_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF HSR_VW AS
$$
BEGIN
	RETURN QUERY SELECT * FROM HSR_VW WHERE HSR_ID = HSR_ID_IN AND HSR_VRSN_ID = HSR_VRSN_ID_IN;
END
$$ LANGUAGE plpgsql;


-- @PROCEDURE 
-- CREATE A COMPONENT OF LINK BETWEEN TWO HSR EVENTS
CREATE OR REPLACE FUNCTION ADD_HSR_LNK
(
	CMP_HSR_ID_IN	IN DECIMAL(20,0), -- THE EVENT WHICH IS THE COMPONENT
	CBC_HSR_ID_IN	IN DECIMAL(20,0), -- THE COMPONENT WHICH IS BEING LINKED TO (CONTAINER)
	LNK_CLS_IN	IN DECIMAL(6,0), -- THE LINK CLASSFIICATION
	CONDUCTION_IN	IN BOOLEAN
) RETURNS VOID AS 
$$
BEGIN
	-- DOES THE TARGET ALREADY HAVE THIS LINK WITH ANOTHER DOC?
	IF((SELECT COUNT(*) FROM HSR_LNK_TBL WHERE HSR_ID = CBC_HSR_ID_IN AND LNK_CLS = LNK_CLS_IN) > 0) THEN
		RAISE EXCEPTION 'CR100: RECORD ALREADY HAS LINK OF SAME CLASS WITH A DIFFERENT DOCUMENT';
	END IF;
	
	-- INSERT THE LINK BETWEEN THE VERSION AND HSR EVENT ID
	INSERT INTO HSR_LNK_TBL(CMP_HSR_ID, HSR_ID, LNK_CLS, CONDUCTION)
		VALUES (CMP_HSR_ID_IN, CBC_HSR_ID_IN, LNK_CLS_IN, CONDUCTION_IN);
	RETURN;
EXCEPTION
	WHEN unique_violation THEN
		RAISE EXCEPTION 'CR006: DUPLICATE LINK, COMPONENT OR REPORT DETECTED';
END
$$ LANGUAGE plpgsql;


-- @REGION
-- COMPONENT FUNCTIONS

-- @PROCEDURE
-- REGISTER AN HSR COMPONENT (HELPS TO RE-CREATE THE HSR EVENT)
CREATE OR REPLACE FUNCTION CRT_COMP
(
	CNTR_TYP_IN	IN VARCHAR(255),
	CNTR_TBL_ID_IN	IN DECIMAL(20,0),
	CNTR_VRSN_ID_IN	IN DECIMAL(20,0),
	CMP_TYP_IN	IN VARCHAR(255),
	CMP_TBL_ID_IN	IN DECIMAL(20,0),
	CMP_ROL_TYP_IN	IN DECIMAL(6)
) RETURNS VOID AS
$$
BEGIN
	
	INSERT INTO CMP_TBL(CNTR_TYP, CNTR_TBL_ID, CNTR_VRSN_ID, CMP_TYP, CMP_TBL_ID, CMP_ROL_TYP)
		VALUES (CNTR_TYP_IN, CNTR_TBL_ID_IN, CNTR_VRSN_ID_IN, CMP_TYP_IN, CMP_TBL_ID_IN, CMP_ROL_TYP_IN);
	RETURN;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- GET ALL COMPONENTS FOR A PARTICULAR HSR EVENT VERSION
--
-- RETURNS: A SET OF COMPONENTS TO BE LOADED
CREATE OR REPLACE FUNCTION GET_COMPS
(
	CNTR_TYP_IN	IN VARCHAR(255),
	CNTR_TBL_ID_IN	IN DECIMAL(20,0),
	CNTR_VRSN_ID_IN	IN DECIMAL(20,0),
	INVRT_IN	IN BOOLEAN
) RETURNS SETOF CMP_TBL AS
$$
BEGIN
	IF INVRT_IN = FALSE THEN
		RETURN QUERY SELECT * FROM CMP_TBL 
			WHERE CNTR_TBL_ID = CNTR_TBL_ID_IN AND CNTR_TYP_IN = CNTR_TYP AND 
				(CNTR_VRSN_ID_IN IS NULL AND CNTR_VRSN_ID IS NULL OR 
				CNTR_VRSN_ID_IN = CNTR_VRSN_ID);
	ELSE
		RETURN QUERY SELECT CMP_ID, CMP_TYP AS CNTR_TYP, CMP_TBL_ID AS CNTR_TBL_ID, CNTR_VRSN_ID AS CNTR_VRSN_ID, CNTR_TYP AS CMP_TYP, CNTR_TBL_ID AS CMP_TBL_ID, CAST(CMP_ROL_TYP + 1 AS NUMERIC(8,0)) AS CMP_ROL_TYP FROM CMP_TBL
			WHERE CMP_TBL_ID = CNTR_TBL_ID_IN AND CNTR_TYP_IN = CMP_TYP;
	END IF;
END;
$$ LANGUAGE plpgsql;
