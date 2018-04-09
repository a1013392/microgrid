/******************************************************************************
 * load_microgrid.sql
 * SQL script for loading tables in sagrid database from data files 
 * (microgrid project):
 * mg_feed.dat
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid

-- Let @delta be the conversion factor from kW to kWh for half-hourly time intervals
SET @delta = 0.50; 

/*****************************************************************************/
/*
\! echo "LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/mg75hh.dat' INTO TABLE mg_hh"
LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/mg75hh.dat'
INTO TABLE mg_hh
COLUMNS TERMINATED BY '\t'
;

\! echo "LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/hh_feed.csv' INTO TABLE hh_feed"
LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/hh_feed.csv'
INTO TABLE hh_feed
COLUMNS TERMINATED BY ','
;

\! echo "INSERT INTO hh_energy SELECT data FROM hh_feed, mg_hh"
INSERT INTO hh_energy
SELECT hf.hh_id, date_time_utc, hh_solar_kwh, hh_bess_chrg_kwh + hh_bess_dchrg_kwh, hh_load_kwh, hh_net_kwh, FALSE
FROM hh_feed hf, mg_hh mh
WHERE hf.hh_id = mh.hh_id
AND mh.mg_code = 'MG75HH'
;
 */
/*****************************************************************************/

\! echo "INSERT INTO hh_power SELECT (*)/@delta FROM hh_energy"
INSERT INTO hh_power
SELECT hh_id, date_time_utc, hh_solar_kwh/@delta, hh_bess_chrg_kwh/@delta, hh_load_kwh/@delta, hh_grid_kwh/@delta, hh_intrpl
FROM hh_energy
;

\! echo "INSERT INTO mg_energy SELECT SUM() FROM mg_hh, hh_energy GROUP BY mg_code, date_time_utc"
INSERT INTO mg_energy
SELECT mg_code, date_time_utc, SUM(hh_solar_kwh), SUM(hh_bess_chrg_kwh), SUM(hh_load_kwh), SUM(hh_grid_kwh)
FROM mg_hh, hh_energy
WHERE mg_hh.hh_id = hh_energy.hh_id
GROUP BY mg_code, date_time_utc
;

\! echo "INSERT INTO mg_power SELECT SUM() FROM mg_hh, hh_power GROUP BY mg_code, date_time_utc"
INSERT INTO mg_power
SELECT mg_code, date_time_utc, SUM(hh_solar_kw), SUM(hh_bess_chrg_kw), SUM(hh_load_kw), SUM(hh_grid_kw)
FROM mg_hh, hh_power
WHERE mg_hh.hh_id = hh_power.hh_id
GROUP BY mg_code, date_time_utc
;

/*****************************************************************************/




