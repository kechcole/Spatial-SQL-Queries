


-- Create table 
CREATE TABLE IF NOT EXISTS "Election".backup
(
    "year" integer,
    "state" character varying(20) COLLATE pg_catalog."default",
    state_code character varying(10) COLLATE pg_catalog."default",
    county character varying(30) COLLATE pg_catalog."default",
    cnty_id integer,
    office character varying(20) COLLATE pg_catalog."default",
    candidate character varying(30) COLLATE pg_catalog."default",
    party character varying(30) COLLATE pg_catalog."default",
    cand_votes integer,
    tot_votes integer,
    "mode" character varying(30) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Election".backup
    OWNER to postgres;

COMMENT ON TABLE "Election".backup
    IS 'contains original model of results table ';


-- Import data 
COPY "US Election".results FROM 
'F:\Programs\PostGRE SQL\US Election Analysis_Github\countypres_results_2000_2020.csv'
with csv header;