DROP TABLE IF EXISTS patients;
CREATE TABLE IF NOT EXISTS patients(
   patient_id serial PRIMARY KEY,
   a1c FLOAT NOT NULL CHECK( 0 < a1c AND a1c <= 14),
   glucose INT NOT NULL,
   fasting BOOLEAN NOT NULL,
   created_on TIMESTAMP NOT NULL DEFAULT NOW()
);
DROP TABLE IF EXISTS errors;
CREATE TABLE IF NOT EXISTS errors(
   error_id serial PRIMARY KEY,
   state TEXT,
   msg TEXT,
   detail TEXT,
   context TEXT
);
INSERT INTO patients (a1c, glucose, fasting) VALUES (5.7, 80, True);
DROP TABLE IF EXISTS ffiec_reci;
CREATE TABLE IF NOT EXISTS ffiec_reci(
   IDRSSD   INTEGER  NOT NULL PRIMARY KEY
  ,RCON0352 BIGINT
  ,RCON2202 BIGINT
  ,RCON2203 BIGINT
  ,RCON2210 BIGINT
  ,RCON2213 BIGINT
  ,RCON2215 BIGINT
  ,RCON2216 BIGINT
  ,RCON2236 BIGINT
  ,RCON2365 BIGINT
  ,RCON2377 BIGINT
  ,RCON2385 BIGINT
  ,RCON2520 BIGINT
  ,RCON2530 BIGINT
  ,RCON5590 BIGINT
  ,RCON6648 BIGINT
  ,RCON6810 BIGINT
  ,RCON6835 BIGINT
  ,RCONB549 BIGINT
  ,RCONB550 BIGINT
  ,RCONB551 BIGINT
  ,RCONB552 BIGINT
  ,RCONF233 BIGINT
  ,RCONHK05 BIGINT
  ,RCONHK06 BIGINT
  ,RCONHK07 BIGINT
  ,RCONHK08 BIGINT
  ,RCONHK09 BIGINT
  ,RCONHK10 BIGINT
  ,RCONHK11 BIGINT
  ,RCONHK12 BIGINT
  ,RCONHK13 BIGINT
  ,RCONHK14 BIGINT
  ,RCONHK15 BIGINT
  ,RCONJ473 BIGINT
  ,RCONJ474 BIGINT
  ,RCONJH83 BIGINT
  ,RCONK220 BIGINT
  ,RCONK222 BIGINT
  ,RCONK223 BIGINT
  ,RCONP752 VARCHAR(36)
  ,RCONP753 BIGINT
  ,RCONP754 BIGINT
  ,RCONP756 BIGINT
  ,RCONP757 BIGINT
  ,RCONP758 BIGINT
  ,RCONP759 BIGINT
  ,FIELD48  VARCHAR(30)
);

\copy ffiec_reci FROM '/tmp/ffiec_records.txt' (DELIMITER E'\t', FORMAT CSV,  HEADER);