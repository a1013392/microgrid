/****************************************************************************** 
 * clean_microgrid.sql
 * SQL script for cleaning data loaded in tables in sagrid database for the
 * microgrid project
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid

-- Simulation horizon is 16 weeks with control/prediction horizon up to 24 hours.
-- Half-hourly time series runs for 16 weeks + 24 hours with start and end timestamps in UTC
-- 5,426 half-hourly intervals (5,424 plus 2 intervals at the end of daylight savings)
SET @start_date_time = '2017-02-03 14:00:00', @end_date_time = '2017-05-27 14:30:00';

\! echo "DELETE FROM hh_energy WHERE date_time_utc < @start_date_time"
DELETE FROM hh_energy
WHERE date_time_utc < @start_date_time
;

\! echo "DELETE FROM hh_energy WHERE date_time_utc > @end_date_time"
DELETE FROM hh_energy
WHERE date_time_utc > @end_date_time
;

\! echo "DELETE FROM hh_energy WHERE NOT EXISTS hh_id IN mg_hh"
DELETE FROM hh_energy
WHERE NOT EXISTS
	(SELECT * FROM mg_hh
	WHERE hh_id = hh_energy.hh_id AND mg_code = 'MG75HH')
;
\! echo "DELETE FROM hh_energy WHERE hh_id NOT IN mg_hh"
DELETE FROM hh_energy
WHERE hh_id NOT IN
	(SELECT hh_id FROM mg_hh
	WHERE mg_code = 'MG75HH')
;

\! echo "INSERT INTO hh_energy missing half-hourly intervals with zero values"
INSERT INTO hh_energy
SELECT mh.hh_id, dt.date_time_utc, 0.0, 0.0, 0.0, 0.0, TRUE
FROM mg_hh mh, date_time dt
WHERE (dt.date_time_utc >= @start_date_time AND dt.date_time_utc <= @end_date_time)
AND NOT EXISTS
	(SELECT * FROM hh_energy he
	WHERE he.hh_id = mh.hh_id AND he.date_time_utc = dt.date_time_utc)
;
