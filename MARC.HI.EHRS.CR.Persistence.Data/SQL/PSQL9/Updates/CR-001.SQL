﻿/**
 * Update: CR-001
 * Applies to: 1.0.0.0 
 * Notes:
 *	- Add performance indexes to key tables
 *	- Move status codes to secondary table
 */

-- TABLE: STATUS CODES
CREATE TABLE STATUS_CDTBL
(
	STATUS_ID	NUMERIC(2) NOT NULL, -- THE STATUS IDENTIFIER
	MNEMONIC VARCHAR(10) NOT NULL, -- THE STATUS TEXT
	CONSTRAINT PK_STATUS_CDTBL PRIMARY KEY (STATUS_ID)
);

-- VALUES
INSERT INTO STATUS_CDTBL VALUES (0, 'Unknown');
INSERT INTO STATUS_CDTBL VALUES (1, 'New');
INSERT INTO STATUS_CDTBL VALUES (2, 'Active');-- = 2,
INSERT INTO STATUS_CDTBL VALUES (4, 'Cancelled');-- = 4,
INSERT INTO STATUS_CDTBL VALUES (6, 'Suspended');-- = 6,
INSERT INTO STATUS_CDTBL VALUES (8, 'Completed');-- = 8,
INSERT INTO STATUS_CDTBL VALUES (16, 'Obsolete');-- = 16,
INSERT INTO STATUS_CDTBL VALUES (20, 'Terminated');-- = 20,
INSERT INTO STATUS_CDTBL VALUES (32, 'Aborted');-- = 32,
INSERT INTO STATUS_CDTBL VALUES (63, 'Normal');-- = 63,
INSERT INTO STATUS_CDTBL VALUES (64, 'Nullified');-- = 64,

-- FUNCTION: GET STATUS
CREATE OR REPLACE FUNCTION GET_STATUS (
	MNEMONIC_IN IN VARCHAR
) RETURNS NUMERIC AS 
$$
BEGIN
	RETURN (SELECT STATUS_ID FROM STATUS_CDTBL WHERE MNEMONIC = MNEMONIC_IN);
END
$$ LANGUAGE plpgsql;

-- INDEX: LOOKUP STATUS BY ID
CREATE INDEX STATUS_CDTBL_MNEMONIC_IDX ON STATUS_CDTBL(MNEMONIC);


-- DROP VIEWS
CREATE OR REPLACE VIEW hsr_vw AS 
 SELECT hsr_vrsn_tbl.hsr_vrsn_id,
    hsr_vrsn_tbl.evt_typ_cd_id,
    hsr_vrsn_tbl.crtn_utc,
    hsr_vrsn_tbl.aut_utc,
    hsr_vrsn_tbl.obslt_utc,
    hsr_vrsn_tbl.refuted_ind,
    hsr_vrsn_tbl.efft_ts_set_id,
    1::varchar(10) as status_cs,
    hsr_vrsn_tbl.lang_cs,
    hsr_vrsn_tbl.hsr_id,
    hsr_vrsn_tbl.rplc_vrsn_id,
    hsr_tbl.hsr_cls
   FROM hsr_tbl
     LEFT JOIN hsr_vrsn_tbl USING (hsr_id)
  ORDER BY hsr_tbl.hsr_id, hsr_vrsn_tbl.crtn_utc DESC;
CREATE OR REPLACE VIEW hsr_ltst_crnt_vrsn_vw AS 
 SELECT DISTINCT ON (hsr_tbl.hsr_id) hsr_vrsn_tbl.hsr_vrsn_id,
    hsr_vrsn_tbl.evt_typ_cd_id,
    hsr_vrsn_tbl.crtn_utc,
    hsr_vrsn_tbl.aut_utc,
    hsr_vrsn_tbl.obslt_utc,
    hsr_vrsn_tbl.refuted_ind,
    hsr_vrsn_tbl.efft_ts_set_id,
    1::varcHar(10) AS status_cs,
    hsr_vrsn_tbl.lang_cs,
    hsr_vrsn_tbl.hsr_id,
    hsr_vrsn_tbl.rplc_vrsn_id,
    hsr_tbl.hsr_cls
   FROM hsr_tbl
     LEFT JOIN hsr_vrsn_tbl USING (hsr_id)
  ORDER BY hsr_tbl.hsr_id, hsr_vrsn_tbl.crtn_utc DESC;

-- DROP DEFAULT
ALTER TABLE HSR_VRSN_TBL ALTER COLUMN STATUS_CS DROP DEFAULT;
ALTER TABLE PSN_VRSN_TBL ALTER COLUMN STATUS DROP DEFAULT;
ALTER TABLE PSN_CTZNSHP_TBL ALTER COLUMN STATUS_CS DROP DEFAULT;
ALTER TABLE PSN_EMPL_TBL ALTER COLUMN STATUS_CS DROP DEFAULT;
ALTER TABLE PSN_RLTNSHP_TBL ALTER COLUMN STATUS_CS DROP DEFAULT;

-- DROP THE ORIGINAL STATUS COLUMNS
ALTER TABLE HSR_VRSN_TBL ALTER COLUMN STATUS_CS TYPE NUMERIC(2) USING GET_STATUS(STATUS_CS);
ALTER TABLE PSN_VRSN_TBL ALTER COLUMN STATUS TYPE NUMERIC(2) USING GET_STATUS(STATUS);
ALTER TABLE PSN_CTZNSHP_TBL ALTER COLUMN STATUS_CS TYPE NUMERIC(2) USING GET_STATUS(STATUS_CS);
ALTER TABLE PSN_EMPL_TBL ALTER COLUMN STATUS_CS TYPE NUMERIC(2) USING GET_STATUS(STATUS_CS);
ALTER TABLE PSN_RLTNSHP_TBL ALTER COLUMN STATUS_CS TYPE NUMERIC(2) USING GET_STATUS(STATUS_CS);

-- SET DEFAULT
ALTER TABLE HSR_VRSN_TBL ALTER COLUMN STATUS_CS SET DEFAULT 1;
ALTER TABLE PSN_VRSN_TBL ALTER COLUMN STATUS SET DEFAULT 1;
ALTER TABLE PSN_CTZNSHP_TBL ALTER COLUMN STATUS_CS SET DEFAULT 1;
ALTER TABLE PSN_EMPL_TBL ALTER COLUMN STATUS_CS SET DEFAULT 1;
ALTER TABLE PSN_RLTNSHP_TBL ALTER COLUMN STATUS_CS SET DEFAULT 1;

-- RENAME COLUMN
ALTER TABLE HSR_VRSN_TBL RENAME COLUMN STATUS_CS TO STATUS_CS_ID;
ALTER TABLE PSN_VRSN_TBL RENAME COLUMN STATUS  TO STATUS_CS_ID;
ALTER TABLE PSN_CTZNSHP_TBL RENAME COLUMN STATUS_CS  TO STATUS_CS_ID;
ALTER TABLE PSN_EMPL_TBL RENAME COLUMN STATUS_CS  TO STATUS_CS_ID;
ALTER TABLE PSN_RLTNSHP_TBL RENAME COLUMN STATUS_CS  TO STATUS_CS_ID;

-- ADD FORIEGN KEYS
ALTER TABLE HSR_VRSN_TBL ADD CONSTRAINT FK_HSR_VRSN_STATUS_CDTBL FOREIGN KEY (STATUS_CS_ID) REFERENCES STATUS_CDTBL(STATUS_ID);
ALTER TABLE PSN_VRSN_TBL ADD CONSTRAINT FK_PSN_VRSN_STATUS_CDTBL FOREIGN KEY (STATUS_CS_ID) REFERENCES STATUS_CDTBL(STATUS_ID);
ALTER TABLE PSN_CTZNSHP_TBL ADD CONSTRAINT FK_PSN_CTZNSHP_STATUS_CDTBL FOREIGN KEY (STATUS_CS_ID) REFERENCES STATUS_CDTBL(STATUS_ID);
ALTER TABLE PSN_EMPL_TBL ADD CONSTRAINT FK_PSN_EMPL_STATUS_CDTBL FOREIGN KEY (STATUS_CS_ID) REFERENCES STATUS_CDTBL(STATUS_ID);
ALTER TABLE PSN_RLTNSHP_TBL ADD CONSTRAINT FK_PSN_RLTNSHP_STATUS_CDTBL FOREIGN KEY (STATUS_CS_ID) REFERENCES STATUS_CDTBL(STATUS_ID);


-- @VIEW
-- HEALTH SERVICES RECORD LATEST VERSION VIEW
CREATE OR REPLACE VIEW HSR_LTST_CRNT_VRSN_VW AS
	SELECT DISTINCT ON (hsr_tbl.hsr_id) hsr_vrsn_tbl.hsr_vrsn_id,
    hsr_vrsn_tbl.evt_typ_cd_id,
    hsr_vrsn_tbl.crtn_utc,
    hsr_vrsn_tbl.aut_utc,
    hsr_vrsn_tbl.obslt_utc,
    hsr_vrsn_tbl.refuted_ind,
    hsr_vrsn_tbl.efft_ts_set_id,
    mnemonic AS status_cs,
    hsr_vrsn_tbl.lang_cs,
    hsr_vrsn_tbl.hsr_id,
    hsr_vrsn_tbl.rplc_vrsn_id,
    hsr_tbl.hsr_cls,
	status_cs_id
	FROM HSR_TBL LEFT JOIN HSR_VRSN_TBL USING (HSR_ID) INNER JOIN STATUS_CDTBL ON (STATUS_ID = STATUS_CS_ID)
	ORDER BY HSR_TBL.HSR_ID, CRTN_UTC DESC;

-- @VIEW
-- HEALTH SERVICES RECORD ALL VERSIONS VIEW
CREATE OR REPLACE VIEW HSR_VW AS
	SELECT 
	    hsr_vrsn_tbl.hsr_vrsn_id,
	    hsr_vrsn_tbl.evt_typ_cd_id,
	    hsr_vrsn_tbl.crtn_utc,
	    hsr_vrsn_tbl.aut_utc,
	    hsr_vrsn_tbl.obslt_utc,
	    hsr_vrsn_tbl.refuted_ind,
	    hsr_vrsn_tbl.efft_ts_set_id,
	    mnemonic as status_cs,
	    hsr_vrsn_tbl.lang_cs,
	    hsr_vrsn_tbl.hsr_id,
	    hsr_vrsn_tbl.rplc_vrsn_id,
	    hsr_tbl.hsr_cls,
		status_cs_id
    	FROM HSR_TBL LEFT JOIN HSR_VRSN_TBL USING(HSR_ID) INNER JOIN STATUS_CDTBL ON (STATUS_ID = STATUS_CS_ID)
	ORDER BY HSR_TBL.HSR_ID, CRTN_UTC DESC;

-- @FUNCTION
-- CREATE A NEW PERSON IN THE DATABASE
-- 
-- RETURNS: THE CRID OF THE CLIENT
DROP FUNCTION IF EXISTS CRT_PSN
(
DECIMAL,
VARCHAR,
CHAR,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
CHAR
)
;
-- REDEFINE
CREATE OR REPLACE FUNCTION CRT_PSN
(
	REG_VRSN_ID_IN		IN DECIMAL(20,0),
	STATUS_ID_IN		IN DECIMAL(2),
	GNDR_CS_IN		IN CHAR(1),
	BRTH_TS_IN		IN DECIMAL,
	MB_ORD_IN		IN DECIMAL(2),
	RLGN_CD_ID_IN		IN DECIMAL(20,0),
	VIP_CD_ID_IN		IN DECIMAL(20,0),
	MRTL_STS_CD_ID_IN	IN DECIMAL(20,0),
	BRTH_PLC_ID_IN		IN DECIMAL(20,0),
	ROL_CS_IN		IN CHAR(3)
) RETURNS TABLE
(
	ID		DECIMAL(20,0),
	VRSN_ID	DECIMAL(20,0)
)
AS
$$
DECLARE
	NEW_ID		DECIMAL;
	NEW_VRSN_ID	DECIMAL;
BEGIN
	NEW_ID := nextval('PSN_SEQ');
	NEW_VRSN_ID := nextval('PSN_SEQ');

	-- INSERT CLIENT DATA
	INSERT INTO PSN_TBL (PSN_ID)
		VALUES (NEW_ID);

	-- INSERT VERSION
	INSERT INTO PSN_VRSN_TBL (PSN_VRSN_ID, PSN_ID, REG_VRSN_ID, STATUS_CS_ID, CRT_UTC, GNDR_CS, BRTH_TS, MB_ORD, RLGN_CD_ID, VIP_CD_ID, MRTL_STS_CD_ID, BRTH_PLC_ID, ROL_CS)
		VALUES (NEW_VRSN_ID, NEW_ID, REG_VRSN_ID_IN, STATUS_ID_IN, CURRENT_TIMESTAMP, GNDR_CS_IN, BRTH_TS_IN, MB_ORD_IN, RLGN_CD_ID_IN, VIP_CD_ID_IN, MRTL_STS_CD_ID_IN, BRTH_PLC_ID_IN, ROL_CS_IN);
	
	-- RETURN SHRID
	RETURN QUERY SELECT NEW_ID, NEW_VRSN_ID;
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- CREATE A VERSION OF A PERSON RECORD
DROP FUNCTION IF EXISTS CRT_PSN_VRSN
(
DECIMAL,
DECIMAL,
VARCHAR,
CHAR,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
DECIMAL,
CHAR
) 
;
-- FUNCTION
CREATE OR REPLACE FUNCTION CRT_PSN_VRSN
(
	PSN_ID_IN		IN DECIMAL(20,0),
	REG_VRSN_ID_IN		IN DECIMAL(20,0),
	STATUS_ID_IN		IN DECIMAL(2),
	GNDR_CS_IN		IN CHAR(1),
	BRTH_TS_IN		IN DECIMAL,
	DCSD_TS_IN		IN DECIMAL,
	MB_ORD_IN		IN DECIMAL(2),
	RLGN_CD_ID_IN		IN DECIMAL(20,0),
	VIP_CD_ID_IN		IN DECIMAL(20,0),
	MRTL_STS_CD_ID_IN	IN DECIMAL(20,0),
	BRTH_PLC_ID_IN		IN DECIMAL(20,0),
	ROL_CS_IN		IN CHAR(3)	
) RETURNS DECIMAL
AS
$$
DECLARE
	NEW_VRSN_ID	DECIMAL;
	PSN_CUR_VRSN_ID DECIMAL;
BEGIN
	NEW_VRSN_ID := nextval('PSN_SEQ');

	-- GET THE CURRENT VERSION IDENTIFIER
	SELECT GET_PSN_CUR_VRSN_ID(PSN_ID_IN) INTO PSN_CUR_VRSN_ID;

	-- SANITY CHECK
	IF PSN_CUR_VRSN_ID IS NULL THEN
		RAISE EXCEPTION 'CR001: CANNOT INSERT VERSION FOR NON-EXISTANT PSN';
	END IF;
	
	-- DUPLICATE THE CURRENT VERSION RECORD INTO THE NEW VERSION RECORD
	INSERT INTO PSN_VRSN_TBL 
		(PSN_VRSN_ID, PSN_ID, RPLC_VRSN_ID, REG_VRSN_ID, STATUS_CS_ID, CRT_UTC, OBSLT_UTC, GNDR_CS, BRTH_TS, DCSD_TS, MB_ORD, RLGN_CD_ID, VIP_CD_ID, MRTL_STS_CD_ID, BRTH_PLC_ID, ROL_CS) 
		SELECT 
			NEW_VRSN_ID,
			PSN_ID_IN,
			PSN_CUR_VRSN_ID,
			REG_VRSN_ID_IN,
			COALESCE(STATUS_ID_IN, STATUS_CS_ID),
			CURRENT_TIMESTAMP,
			NULL,
			COALESCE(GNDR_CS_IN, GNDR_CS),
			COALESCE(BRTH_TS_IN, BRTH_TS),
			COALESCE(DCSD_TS_IN, DCSD_TS),
			COALESCE(MB_ORD_IN, MB_ORD),
			COALESCE(RLGN_CD_ID_IN, RLGN_CD_ID),
			COALESCE(VIP_CD_ID_IN, VIP_CD_ID),
			COALESCE(MRTL_STS_CD_ID_IN, MRTL_STS_CD_ID),
			COALESCE(BRTH_PLC_ID_IN, BRTH_PLC_ID),
			COALESCE(ROL_CS_IN, ROL_CS)
		FROM PSN_VRSN_TBL WHERE
			PSN_VRSN_ID = PSN_CUR_VRSN_ID;

	-- OBSOLETE THE OLD VERSION
	UPDATE PSN_VRSN_TBL SET OBSLT_UTC = CURRENT_TIMESTAMP, STATUS_CS_ID = 16 --'Obsolete'
		WHERE PSN_VRSN_ID = PSN_CUR_VRSN_ID;

	--RETURN (SELECT CRT_HSR_VRSN((SELECT HSR_ID FROM HSR_VRSN_TBL INNER JOIN PSN_VRSN_TBL ON (HSR_VRSN_ID = REG_VRSN_ID) WHERE PSN_VRSN_ID = PSN_CUR_VRSN_ID), NULL, NULL, NULL, 16, NULL));
	-- RETURN NEW VERSION ID
	RETURN NEW_VRSN_ID;		

END;
$$ LANGUAGE plpgsql;


-- @PROCEDURE
-- LINK TWO CLIENTS TOGETHER
DROP FUNCTION IF EXISTS CRT_PSN_RLTNSHP
(
	DECIMAL,
	DECIMAL,
	VARCHAR,
	VARCHAR
) ;
CREATE OR REPLACE FUNCTION CRT_PSN_RLTNSHP
(
	SRC_PSN_ID_IN		IN DECIMAL(20),
	TRG_PSN_ID_IN		IN DECIMAL(20),
	STATUS_CS_ID_IN		IN DECIMAL(2),
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
		RETURN RLTNSHP_ID_ID;
	ELSE -- NO
		SELECT GET_PSN_CUR_VRSN_ID(TRG_PSN_ID_IN) INTO SRC_VRSN_ID;
		RLTNSHP_ID_ID := nextval('PSN_RLTNSHP_SEQ');
		INSERT INTO PSN_RLTNSHP_TBL (RLTNSHP_ID, SRC_PSN_ID, TRG_PSN_ID, KIND_CS, EFFT_VRSN_ID, STATUS_CS_ID) VALUES
			(RLTNSHP_ID_ID, SRC_PSN_ID_IN, TRG_PSN_ID_IN, KIND_IN, SRC_VRSN_ID, COALESCE(STATUS_CS_ID_IN, 2));
	END IF;

	RETURN RLTNSHP_ID_ID;
END
$$ LANGUAGE plpgsql;


-- @PROCEDURE
-- CREATE AN EMPLOYMENT RECORD
DROP FUNCTION IF EXISTS CRT_PSN_EMPL
(
	DECIMAL,
	DECIMAL,
	DECIMAL,
	DECIMAL,
	VARCHAR
);
CREATE OR REPLACE FUNCTION CRT_PSN_EMPL
(
	PSN_ID_IN		IN DECIMAL(20),
	PSN_VRSN_ID_IN		IN DECIMAL(20),
	EMPL_CD_ID		IN DECIMAL(20),
	EFFT_TS_SET_ID_IN	IN DECIMAL(20),
	STATUS_CD_ID_IN		IN DECIMAL
) RETURNS DECIMAL AS 
$$
DECLARE
	EMP_ID_ID	DECIMAL;
BEGIN
	EMP_ID_ID := nextval('PSN_EMPL_SEQ');
	INSERT INTO PSN_EMPL_TBL (EMPL_ID, PSN_ID, EMPL_CD_ID, EFFT_TS_SET_ID, STATUS_CS_ID, EFFT_VRSN_ID) VALUES
		(EMP_ID_ID, PSN_ID_IN, EMPL_CD_ID_IN, EFFT_TS_SET_ID_IN, COALESCE(STATUS_CD_ID_IN, 2), EFFT_VRSN_ID);
	RETURN EMP_ID_ID;
END
$$ LANGUAGE plpgsql;


-- @PROCEDURE
-- CREATE A CITIZENSHIP
DROP FUNCTION IF EXISTS CRT_PSN_CTZNSHP
(
	DECIMAL,
	DECIMAL,
	CHAR,
	VARCHAR,
	DECIMAL,
	VARCHAR
);
CREATE OR REPLACE FUNCTION CRT_PSN_CTZNSHP
(
	PSN_ID_IN		IN DECIMAL(20),
	PSN_VRSN_ID_IN		IN DECIMAL(20),
	NTN_CS_IN		IN CHAR(3),
	NTN_NAME_IN		IN VARCHAR(200),
	EFFT_TS_SET_ID_IN	IN DECIMAL(20),
	STATUS_CD_ID_IN		IN DECIMAL(2)
) RETURNS DECIMAL AS 
$$
DECLARE
	CTZN_ID_ID	DECIMAL;
BEGIN
	CTZN_ID_ID := nextval('NTN_SEQ');
	INSERT INTO PSN_CTZNSHP_TBL (CTZN_ID, PSN_ID, NTN_CS, NTN_NAME, EFFT_TS_SET_ID, STATUS_CS_ID, EFFT_VRSN_ID) VALUES
		(CTZN_ID_ID, PSN_ID_IN, NTN_CS_IN, NTN_NAME_IN, EFFT_TS_SET_ID_IN, COALESCE(STATUS_CD_ID_IN, 2), EFFT_VRSN_ID);
	RETURN CTZN_ID_ID;
END
$$ LANGUAGE plpgsql;


-- @FUNCTION
-- CREATE A NEW HEALTH SERVICE RECORD
--
-- PURPOSE: CREATES THE HSR RECORD AND A PRIMARY VERSION FOR THE HSR 
--
-- RETURNS: THE ID OF THE HSR RECORD VERSION
DROP FUNCTION IF EXISTS CRT_HSR
(
	DECIMAL,
	DECIMAL,
	BOOLEAN,
	DECIMAL,
	VARCHAR,
	TIMESTAMPTZ,
	VARCHAR
);
CREATE OR REPLACE FUNCTION CRT_HSR
(
	HSR_CLS_IN		IN DECIMAL(4,0),
	EVT_TYP_CD_ID_IN	IN DECIMAL(20,0),
	REFUTED_IND_IN		IN BOOLEAN,
	EFFT_TS_SET_ID_IN	IN DECIMAL(20,0),
	STATUS_CS_ID_IN		IN DECIMAL(2),
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
	INSERT INTO HSR_VRSN_TBL (HSR_VRSN_ID, AUT_UTC, HSR_ID, EVT_TYP_CD_ID, REFUTED_IND, EFFT_TS_SET_ID, STATUS_CS_ID, LANG_CS)
		VALUES (HSR_VRSN_ID_VAL, AUT_UTC_IN, HSR_ID_VAL, EVT_TYP_CD_ID_IN, REFUTED_IND_IN, EFFT_TS_SET_ID_IN, STATUS_CS_ID_IN, LANG_CS_IN);
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
	RETURN (SELECT CRT_HSR_VRSN(HSR_ID_IN, NULL, NULL, NULL, 64, NULL));
END
$$ LANGUAGE plpgsql;


-- @FUNCTION
-- CREATE A NEW HEALTH SERVICE RECORD VERSION
-- 
-- PURPOSE: INSERTS A NEW HEALTH SERVICE RECORD VERSION INTO THE HSR_VRSN TABLE, DUPLICATES THE VERSION
--
-- RETURNS: THE IDENTIFIER OF THE NEW VERSION
DROP FUNCTION IF EXISTS CRT_HSR_VRSN
(
	DECIMAL, -- THE HSR ID FOR WHICH THE NEW VERSION IS CREATED
	DECIMAL, 
	BOOLEAN,
	DECIMAL,
	VARCHAR,
	TIMESTAMPTZ,
	VARCHAR
) ;
CREATE OR REPLACE FUNCTION CRT_HSR_VRSN
(
	HSR_ID_IN		IN DECIMAL(20,0), -- THE HSR ID FOR WHICH THE NEW VERSION IS CREATED
	EVT_TYP_CD_ID_IN	IN DECIMAL(20,0), 
	REFUTED_IND_IN		IN BOOLEAN,
	EFFT_TS_SET_ID_IN	IN DECIMAL(20,0),
	STATUS_CS_ID_IN		IN DECIMAL(2),
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
			COALESCE(STATUS_CS_ID_IN, STATUS_CS_ID),
			COALESCE(LANG_CS_IN, LANG_CS),
			HSR_ID_IN,
			HSR_CUR_VRSN_ID
		FROM HSR_VRSN_TBL WHERE
			HSR_VRSN_ID = HSR_CUR_VRSN_ID;

	-- OBSOLETE THE OLD VERSION
	UPDATE HSR_VRSN_TBL SET OBSLT_UTC = CURRENT_TIMESTAMP, STATUS_CS_ID = 16 
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
	RETURN QUERY SELECT DISTINCT ON (hsr_tbl.hsr_id) hsr_vrsn_tbl.hsr_vrsn_id, hsr_vrsn_tbl.evt_typ_cd_id, hsr_vrsn_tbl.crtn_utc, hsr_vrsn_tbl.aut_utc, hsr_vrsn_tbl.obslt_utc, hsr_vrsn_tbl.refuted_ind, hsr_vrsn_tbl.efft_ts_set_id, status_cdtbl.mnemonic as status_cs, hsr_vrsn_tbl.lang_cs, hsr_vrsn_tbl.hsr_id, hsr_vrsn_tbl.rplc_vrsn_id, hsr_tbl.hsr_cls, status_cs_id
	   FROM hsr_vrsn_tbl 
	   INNER JOIN hsr_tbl USING (hsr_id)
	   INNER JOIN status_cdtbl ON (hsr_vrsn_tbl.status_cs_id = status_cdtbl.status_id)
	   WHERE hsr_tbl.hsr_id = hsr_id_in AND
	   obslt_utc IS NULL
	  ORDER BY hsr_tbl.hsr_id, hsr_vrsn_tbl.hsr_vrsn_id, hsr_vrsn_tbl.crtn_utc DESC;
END
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
	SELECT CRT_PSN_VRSN(PSN_ID_IN, REG_VRSN_ID_IN, 64, NULL, NULL, NULL, NULL, NULL);
END;
$$ LANGUAGE plpgsql;
	

-- INDEX: LOOKUP HSR VERSION BY CREATION TIME 
CREATE INDEX hsr_vrsn_tbl_crtn_utc_idx ON hsr_vrsn_tbl(crtn_utc);
-- INDEX: LOOKUP HSR VERSION BY OBSOLETION TIME
CREATE INDEX hsr_vrsn_tbl_obslt_utc_idx ON hsr_vrsn_tbl(obslt_utc);
-- INDEX: LOOKUP HSR VERSION BY STATUS
CREATE INDEX hsr_vrsn_tbl_status_cs_idx ON hsr_vrsn_tbl(status_cs_id);
-- INDEX: LOOKUP PERSON VERSION BY STATUS
CREATE INDEX psn_vrsn_tbl_status_cs_idx ON psn_vrsn_tbl(status_cs_id);
-- INDEX: LOOKUP HSR CLASS
CREATE INDEX hsr_tbl_hsr_cls_idx ON hsr_tbl(hsr_cls);

-- @FUNCTION
-- GET DATABASE SCHEMA VERSION
--
-- RETURNS: THE MAJOR, MINOR AND RELEASE NUMBER OF THE DATABASE SCHEMA
CREATE OR REPLACE FUNCTION GET_SCH_VER() RETURNS VARCHAR AS
$$
BEGIN
	RETURN '1.1.0.0';
END;
$$ LANGUAGE plpgsql;

CREATE INDEX ADDR_CMP_SET_VALUE_CLS_IDX ON ADDR_CMP_TBL(ADDR_CMP_VALUE, ADDR_CMP_CLS);
CREATE INDEX NAME_CMP_SET_VALUE_CLS_IDX ON NAME_CMP_TBL(NAME_CMP_VALUE, NAME_CMP_CLS);
CREATE INDEX PSN_ALT_ID_ID_DOMAIN_IDX ON PSN_ALT_ID_TBL(ID_DOMAIN);

-- PERFORMANCE FOR QUERY
CREATE INDEX PSN_VRSN_OBSLT_UTC_IDX ON PSN_VRSN_TBL(OBSLT_UTC);


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
--
-- SOME PARAMETERS
--
--	NAME_MATCH_IN : THE DESIRED MATCHING STRENGTH (0 - 5)
--				5 	= USE EXACT STRING MATCHING
--				4 	= USE 100% SOUNDEX MATCHING
--				<3 	= USE < 75% SOUNDEX MATCHING
--
--	USE_VARIANTS_IN	: TRUE IF NAME VARIANTS SHOULD BE USED
--		WHEN NAME_MATCH_IN =
--				6	= NAME VARIANTS MUST BE EXACT MATCHES
--				5	= PATTERN MATCH USING ~~*
--				4	= NAME VARIANTS USE 100% SOUNDEX MATCHES
CREATE OR REPLACE FUNCTION FIND_PSN_BY_NAME_SET(
	NAME_CMP_VAL_IN	IN VARCHAR[],
	NAME_CMP_CLS_IN IN DECIMAL[],
	NAME_MATCH_IN	IN DECIMAL,
	USE_VARIANTS_IN	IN BOOLEAN,
	NAME_SET_USE_IN	IN DECIMAL(20),
	MATCHES_IN 	IN DECIMAL[]
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS
$$
DECLARE
	CNCMP			DECIMAL;
	TMP_NAME_RET_TBL	DECIMAL[];
	TMP_NAME_RES_TBL	DECIMAL[];
	T_SOUNDEX		CHAR(4);
BEGIN


	T_SOUNDEX := SOUNDEX(NAME_CMP_VAL_IN[1]);
	-- FILTER THE FIRST SET
	TMP_NAME_RET_TBL := ARRAY(SELECT A.NAME_SET_ID FROM NAME_CMP_TBL A INNER JOIN NAME_CDTBL ON (A.NAME_CMP_VALUE = NAME_CDTBL.NAME_ID)
		WHERE 
			(
			(NAME_MATCH_IN = 6 AND NAME_VALUE ~* NAME_CMP_VAL_IN[1]) -- EXACT MATCH
				OR
			(NAME_MATCH_IN = 5 AND NAME_VALUE ~~* NAME_CMP_VAL_IN[1]) -- PATTERN MATCH
				OR
				  -- MATCH ON SOUNDEX
			(NAME_MATCH_IN = 4 AND (NAME_SOUNDEX = T_SOUNDEX OR NAME_VALUE ~~* NAME_CMP_VAL_IN[1])) 
				OR
				  -- FUZZY SOUNDEX MATCH
			(NAME_MATCH_IN < 4 AND DIFFERENCE(NAME_CDTBL.NAME_VALUE, NAME_CMP_VAL_IN[1]) >= NAME_MATCH_IN)
				OR
				  -- EXACT MATCH ON VARIANT
			(USE_VARIANTS_IN = TRUE AND NAME_MATCH_IN = 6 AND NAME_CMP_CLS_IN[1] = 1 AND UPPER(NAME_VALUE) IN (SELECT B.SYN_NAME FROM NAME_CMP_SYN_CDTBL B WHERE B.PRI_NAME ~* NAME_CMP_VAL_IN[1]))
				  -- PATTERN SOUNDEX
				OR
			(USE_VARIANTS_IN = TRUE AND NAME_MATCH_IN BETWEEN 4 AND 5 AND NAME_CMP_CLS_IN[1] = 1 AND UPPER(NAME_VALUE) IN (SELECT B.SYN_NAME FROM NAME_CMP_SYN_CDTBL B WHERE B.PRI_NAME ~~* NAME_CMP_VAL_IN[1]))
				OR
				  -- FUZZY SOUNDEX MATCH ON VARIANT
			(USE_VARIANTS_IN = TRUE AND NAME_MATCH_IN < 4 AND NAME_CMP_CLS_IN[1] = 1 AND UPPER(NAME_VALUE) IN (SELECT B.SYN_NAME FROM NAME_CMP_SYN_CDTBL B WHERE B.PRI_SOUNDEX = T_SOUNDEX AND STRENGTH >= NAME_MATCH_IN))

			) 
		AND -- SOUNDS LIKE PORTION
			NAME_CMP_CLS = NAME_CMP_CLS_IN[1]);

	-- SUBSEQUENT
	IF(ARRAY_LOWER(NAME_CMP_VAL_IN, 1) < ARRAY_UPPER(NAME_CMP_VAL_IN, 1)) THEN
		FOR CNCMP IN ARRAY_LOWER(NAME_CMP_VAL_IN, 1) + 1 .. ARRAY_UPPER(NAME_CMP_VAL_IN, 1) LOOP
			T_SOUNDEX := SOUNDEX(NAME_CMP_VAL_IN[CNCMP]);
			TMP_NAME_RET_TBL := ARRAY(
				SELECT A.NAME_SET_ID FROM NAME_CMP_TBL A INNER JOIN NAME_CDTBL ON (A.NAME_CMP_VALUE = NAME_CDTBL.NAME_ID)
				WHERE 
					(
					(NAME_MATCH_IN = 6 AND NAME_VALUE ~* NAME_CMP_VAL_IN[CNCMP]) 
						OR
					(NAME_MATCH_IN = 5 AND NAME_VALUE ~~* NAME_CMP_VAL_IN[CNCMP])
						OR
					(NAME_MATCH_IN = 4 AND (NAME_SOUNDEX = T_SOUNDEX OR NAME_VALUE ~~* NAME_CMP_VAL_IN[CNCMP])) 
						OR
					(NAME_MATCH_IN < 4 AND DIFFERENCE(NAME_CDTBL.NAME_VALUE, NAME_CMP_VAL_IN[CNCMP]) >= NAME_MATCH_IN)
						OR
					(USE_VARIANTS_IN = TRUE AND NAME_MATCH_IN = 6 AND NAME_CMP_CLS_IN[CNCMP] = 1 AND UPPER(NAME_VALUE) IN (SELECT B.SYN_NAME FROM NAME_CMP_SYN_CDTBL B WHERE B.PRI_NAME ~* NAME_CMP_VAL_IN[CNCMP]))
						OR
					(USE_VARIANTS_IN = TRUE AND NAME_MATCH_IN >= 4 AND NAME_CMP_CLS_IN[CNCMP] = 1 AND UPPER(NAME_VALUE) IN (SELECT B.SYN_NAME FROM NAME_CMP_SYN_CDTBL B WHERE B.PRI_NAME ~~* NAME_CMP_VAL_IN[CNCMP]))
						OR
					(USE_VARIANTS_IN = TRUE AND NAME_MATCH_IN < 4 AND NAME_CMP_CLS_IN[CNCMP] = 1 AND UPPER(NAME_VALUE) IN (SELECT B.SYN_NAME FROM NAME_CMP_SYN_CDTBL B WHERE B.PRI_SOUNDEX = T_SOUNDEX AND STRENGTH >= 3))
					)
				AND -- SOUNDS LIKE PORTION
					NAME_CMP_CLS = NAME_CMP_CLS_IN[CNCMP]
				AND 
					A.NAME_SET_ID = ANY (TMP_NAME_RET_TBL));

		END LOOP;
	END IF;
	
	RETURN QUERY SELECT PSN_NAME_SET_TBL.PSN_ID FROM PSN_NAME_SET_TBL WHERE 
		PSN_NAME_SET_TBL.PSN_ID = ANY(MATCHES_IN)
			AND
		PSN_NAME_SET_TBL.NAME_SET_ID = ANY (TMP_NAME_RET_TBL) 
			AND
		(NAME_SET_USE_IN IS NOT NULL AND NAME_SET_USE = NAME_SET_USE_IN OR NAME_SET_USE_IN IS NULL) 
			AND
		OBSLT_VRSN_ID IS NULL;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- FIND A PERSON IDENTIFIER BY THE BIRTHTIME
CREATE OR REPLACE FUNCTION FIND_PSN_BY_BRTH_TS(
	TS_VALUE_IN	IN TIMESTAMPTZ,
	TS_PRECISION_IN	IN CHAR(1),
	MATCHES_IN	IN DECIMAL[]
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS
$$
DECLARE
	TS_PRECISION_IVL	INTERVAL;
	TS_VALUE_DATE		DATE; -- FOR DATE QUERIES
BEGIN
	
	-- DETERMINE THE IVL
	IF TS_PRECISION_IN = 'Y' THEN
		TS_PRECISION_IVL = '1 YEAR'::INTERVAL;
		TS_VALUE_DATE = CAST(TS_VALUE_IN AS DATE);
	ELSIF TS_PRECISION_IN = 'M' THEN
		TS_PRECISION_IVL = '1 MONTH'::INTERVAL;
		TS_VALUE_DATE = CAST(TS_VALUE_IN AS DATE);
	ELSIF TS_PRECISION_IN = 'D' THEN
		TS_PRECISION_IVL = '1 DAY'::INTERVAL;
		TS_VALUE_DATE = CAST(TS_VALUE_IN AS DATE);
	ELSIF TS_PRECISION_IN = 'H' THEN
		TS_PRECISION_IVL = '1 HOUR'::INTERVAL;
	ELSIF TS_PRECISION_IN = 'm' THEN
		TS_PRECISION_IVL = '1 MINUTE'::INTERVAL;
	ELSIF TS_PRECISION_IN = 'S' THEN
		TS_PRECISION_IVL = '1 SECOND'::INTERVAL;
	ELSIF TS_PRECISION_IN = 'F' THEN
		TS_PRECISION_IVL = '1 DAY'::INTERVAL;
	END IF;

	-- EXECUTE QUERY
	RETURN QUERY  SELECT PSN_VRSN_TBL.PSN_ID FROM 
		PSN_VRSN_TBL INNER JOIN TS_TBL ON (PSN_VRSN_TBL.BRTH_TS = TS_TBL.TS_ID) 
	WHERE 
		TS_VALUE BETWEEN TS_VALUE_IN AND TS_VALUE_IN + TS_PRECISION_IVL::INTERVAL - '1 MILLISECOND'::INTERVAL 
			AND 	
		PSN_VRSN_TBL.OBSLT_UTC IS NULL
			AND
		PSN_VRSN_TBL.PSN_ID =ANY(MATCHES_IN);
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- LOOKUP CANDIDATES BY GENDER CODE
CREATE OR REPLACE FUNCTION FIND_PSN_BY_GNDR_CS (
	GNDR_CS_IN	IN VARCHAR(2),
	MATCHES_IN	IN DECIMAL[]	
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS 
$$
BEGIN
	RETURN QUERY SELECT PSN_VRSN_TBL.PSN_ID FROM PSN_VRSN_TBL WHERE GNDR_CS = GNDR_CS_IN AND OBSLT_UTC IS NULL AND PSN_VRSN_TBL.PSN_ID =ANY(MATCHES_IN);
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- LOOKUP CANDIDATES BY TELECOM
CREATE OR REPLACE FUNCTION FIND_PSN_BY_TEL(
	TEL_VALUE_IN	IN VARCHAR(255),
	TEL_USE_IN	IN VARCHAR(32),
	MATCHES_IN	IN DECIMAL[]
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS 
$$
BEGIN
	RETURN QUERY SELECT PSN_TEL_TBL.PSN_ID FROM PSN_TEL_TBL WHERE OBSLT_VRSN_ID IS NULL AND TEL_VALUE = TEL_VALUE_IN AND
		(TEL_USE_IN IS NOT NULL AND TEL_USE = TEL_USE_IN OR TEL_USE_IN IS NULL) AND PSN_TEL_TBL.PSN_ID =ANY(MATCHES_IN);
END
$$ LANGUAGE plpgsql;


-- @FUNCTION
-- LOOKUP CANDIDATES BY TELECOM
CREATE OR REPLACE FUNCTION FIND_PSN_BY_TEL_LIKE(
	TEL_VALUE_IN	IN VARCHAR(255),
	TEL_USE_IN	IN VARCHAR(32),
	MATCHES_IN	IN DECIMAL[]
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS 
$$
BEGIN
	RETURN QUERY SELECT PSN_TEL_TBL.PSN_ID FROM PSN_TEL_TBL WHERE OBSLT_VRSN_ID IS NULL AND TEL_VALUE LIKE TEL_VALUE_IN AND
		(TEL_USE_IN IS NOT NULL AND TEL_USE = TEL_USE_IN OR TEL_USE_IN IS NULL) AND PSN_TEL_TBL.PSN_ID =ANY(MATCHES_IN);
END
$$ LANGUAGE plpgsql;

-- @FUNCTION
-- FIND ADDR SETS
--
CREATE OR REPLACE FUNCTION FIND_PSN_BY_ADDR_SET(
	ADDR_CMP_VAL_IN	IN VARCHAR[],
	ADDR_CMP_CLS_IN IN DECIMAL[],
	ADDR_SET_USE_IN	IN DECIMAL(20),
	MATCHES_IN	IN DECIMAL[]
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS
$$
DECLARE
	CNCMP			DECIMAL;
	TMP_ADDR_RET_TBL	DECIMAL[];
	TMP_ADDR_RES_TBL	DECIMAL[];
BEGIN


	-- FILTER THE FIRST SET
	TMP_ADDR_RET_TBL := ARRAY(SELECT A.ADDR_SET_ID FROM ADDR_CMP_TBL A INNER JOIN ADDR_CDTBL ON (A.ADDR_CMP_VALUE = ADDR_CDTBL.ADDR_ID)
		WHERE UPPER(ADDR_VALUE) = UPPER(ADDR_CMP_VAL_IN[1])
		AND 
			ADDR_CMP_CLS = ADDR_CMP_CLS_IN[1]);

	-- SUBSEQUENT
	IF(ARRAY_LOWER(ADDR_CMP_VAL_IN, 1) < ARRAY_UPPER(ADDR_CMP_VAL_IN, 1)) THEN
		FOR CNCMP IN ARRAY_LOWER(ADDR_CMP_VAL_IN, 1) + 1 .. ARRAY_UPPER(ADDR_CMP_VAL_IN, 1) LOOP
			TMP_ADDR_RET_TBL := ARRAY(
				SELECT A.ADDR_SET_ID FROM ADDR_CMP_TBL A INNER JOIN ADDR_CDTBL ON (A.ADDR_CMP_VALUE = ADDR_CDTBL.ADDR_ID)
				WHERE UPPER(ADDR_VALUE) = UPPER(ADDR_CMP_VAL_IN[CNCMP]) 
				AND 
					ADDR_CMP_CLS = ADDR_CMP_CLS_IN[CNCMP]
				AND 
					A.ADDR_SET_ID = ANY (TMP_ADDR_RET_TBL));

		END LOOP;
	END IF;
	
	RETURN QUERY SELECT PSN_ADDR_SET_TBL.PSN_ID FROM PSN_ADDR_SET_TBL WHERE 
		PSN_ADDR_SET_TBL.ADDR_SET_ID = ANY (TMP_ADDR_RET_TBL) 
			AND
		(ADDR_SET_USE_IN IS NOT NULL AND ADDR_SET_USE = ADDR_SET_USE_IN OR ADDR_SET_USE_IN IS NULL) 
			AND
		OBSLT_VRSN_ID IS NULL
			AND
		PSN_ADDR_SET_TBL.PSN_ID =ANY(MATCHES_IN);
END;
$$ LANGUAGE plpgsql;

-- FIND PERSON BY EXTERNAL IDENTIFIER DOMAIN
CREATE OR REPLACE FUNCTION FIND_PSN_EXTERN
(
	ID_DOMAIN_IN	IN VARCHAR,
	MATCHES_IN	IN DECIMAL[]
) RETURNS TABLE(PSN_ID NUMERIC(20)) AS
$$
BEGIN
	RETURN QUERY SELECT PSN_ALT_ID_TBL.PSN_ID FROM PSN_ALT_ID_TBL WHERE ID_DOMAIN = ID_DOMAIN_IN AND 
		IS_HCN = TRUE AND IS_PRVT = FALSE AND
		OBSLT_VRSN_ID IS NULL
		AND 
		PSN_ALT_ID_TBL.PSN_ID =ANY(MATCHES_IN);
END;
$$ LANGUAGE PLPGSQL;
CREATE INDEX PSN_ALT_ID_VALUE_IDX ON PSN_ALT_ID_TBL(ID_VALUE);

-- MARK ANY MERGES POINTING TO THE CURRENT HSR AS OBSOLETE
CREATE OR REPLACE FUNCTION OBSLT_MRG
(
	HSR_ID_IN IN DECIMAL(20,0)
) RETURNS VOID AS 
$$
BEGIN
	UPDATE HSR_MRG_CAND_TBL SET OBSLT_UTC = CURRENT_TIMESTAMP, RSLV_OUTC_CS = 'OBS' 
		WHERE HSR_ID = HSR_ID_IN OR CAND_HSR_ID = HSR_ID_IN AND OBSLT_UTC IS NULL;
END;
$$ LANGUAGE plpgsql;

-- @FUNCTION GET PSN TABLE
DROP FUNCTION IF EXISTS GET_PSN_HSR_EVT
(
	DECIMAL, DECIMAL
);

CREATE OR REPLACE FUNCTION GET_PSN_HSR_EVT
(
	PSN_ID_IN	IN DECIMAL(20,0),
	PSN_VRSN_ID_IN	IN DECIMAL(20,0)
) RETURNS SETOF HSR_VRSN_TBL AS 
$$
BEGIN
	RETURN QUERY SELECT HSR_VRSN_TBL.* FROM PSN_VRSN_TBL INNER JOIN HSR_VRSN_TBL ON (REG_VRSN_ID = HSR_VRSN_ID) WHERE PSN_ID = PSN_ID_IN AND PSN_VRSN_ID = PSN_VRSN_ID_IN;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX PSN_ADDR_SET_ADDR_SET_ID_IDX ON PSN_ADDR_SET_TBL(ADDR_SET_ID);
CREATE INDEX PSN_NAME_SET_NAME_SET_ID_IDX ON PSN_NAME_SET_TBL(NAME_SET_ID);