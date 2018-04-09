/******************************************************************************
 * date_time_act.sql
 * SQL script for loading date_time table 
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid

\! echo "CREATE TABLE date_time_30min"
DROP TABLE IF EXISTS date_time_30min;
CREATE TABLE date_time_30min (
	date_time datetime not null
);

\! echo "CREATE TABLE date_time"
DROP TABLE IF EXISTS date_time;
CREATE TABLE date_time (
	date_time_utc datetime not null,
	date_time_act datetime not null,
	date_act date null,
	time_act time null
);
CREATE UNIQUE INDEX utcidx
ON date_time (date_time_utc);
CREATE INDEX actidx
ON date_time (date_time_act);
DESCRIBE date_time;

\! echo "LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/date_time_30min.dat' INTO TABLE date_time_30min"
LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/date_time_30min.dat'
INTO TABLE date_time_30min
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACDT 2016"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '10:30:00')
FROM date_time_30min
WHERE date_time > '2015-10-03 16:30:00' AND date_time <= '2016-04-02 15:30:00'
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACST 2016"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '09:30:00')
FROM date_time_30min
WHERE date_time > '2016-04-02 15:30:00' AND date_time <= '2016-10-01 16:30:00'
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACDT 2017"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '10:30:00')
FROM date_time_30min
WHERE date_time > '2016-10-01 16:30:00' AND date_time <= '2017-04-01 15:30:00'
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACST 2017"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '09:30:00')
FROM date_time_30min
WHERE date_time > '2017-04-01 15:30:00' AND date_time <= '2017-09-30 16:30:00'
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACDT 2018"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '10:30:00')
FROM date_time_30min
WHERE date_time > '2017-09-30 16:30:00' AND date_time <= '2018-03-31 15:30:00'
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACST 2018"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '09:30:00')
FROM date_time_30min
WHERE date_time > '2018-03-31 15:30:00' AND date_time <= '2018-10-06 16:30:00'
;

\! echo "INSERT INTO date_time SELECT date_time_utc, date_time_act (ADDTIME) -- ACDT 2019"
INSERT INTO date_time (date_time_utc, date_time_act)
SELECT date_time, ADDTIME(date_time, '10:30:00')
FROM date_time_30min
WHERE date_time > '2018-10-06 16:30:00' AND date_time <= '2019-04-06 15:30:00'
;

\!echo "UPDATE date_time SET date_act = DATE(date_time_act), time_act = TIME(date_time_act)"
UPDATE date_time
SET date_act = DATE(date_time_act), time_act = TIME(date_time_act)
;

\! echo "DROP TABLE date_time_30min"
DROP TABLE date_time_30min
;
