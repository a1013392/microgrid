/****************************************************************************** 
 * tariff.sql
 * SQL script for loading tariff related tables
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid


\! echo "CREATE TABLE tariff"
DROP TABLE IF EXISTS tariff;
CREATE TABLE tariff (
	tariff_code char(8) not null,
	time_act time not null,
	price_kwh float not null,
	feedin_kwh float not null
);
CREATE UNIQUE INDEX tctidx
ON tariff (tariff_code, time_act);
DESCRIBE tariff;


\! echo "CREATE TABLE impose_tariff"
DROP TABLE IF EXISTS impose_tariff;
CREATE TABLE impose_tariff (
	date_act date not null,
	tariff_code char(8) null
);
CREATE UNIQUE INDEX dtcidx
ON impose_tariff (date_act, tariff_code);
DESCRIBE impose_tariff;


\! echo "LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/tariff.dat' INTO TABLE tariff"
LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/tariff.dat'
INTO TABLE tariff
;


\! echo "INSERT INTO impose_tariff SELECT DISTINCT date_act"
INSERT INTO impose_tariff (date_act)
SELECT DISTINCT date_act
FROM date_time
;

/*
\!echo "UPDATE impose_tariff SET tariff_code = 'FLAT'"
UPDATE impose_tariff
SET tariff_code = 'FLAT'
;
 */

\!echo "UPDATE impose_tariff SET tariff_code = 'TOD'"
UPDATE impose_tariff
SET tariff_code = 'TOD'
;

\!echo "UPDATE impose_tariff SET tariff_code = 'TODPEAK'"
UPDATE impose_tariff
SET tariff_code = 'TODPEAK'
WHERE MONTH(date_act) < 4 or MONTH(date_act) > 10
;
