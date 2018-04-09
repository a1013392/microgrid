/******************************************************************************
 * export_microgrid.sql
 * SQL script for exporting data files from sagrid database
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid

SET @start_date_time = '2017-02-03 14:00:00', @end_date_time = '2017-05-27 14:30:00';
--SET @start_date_time = '2017-02-03 14:00:00', @end_date_time = '2017-05-26 14:30:00';
--SET @start_date_time = '2017-02-03 14:00:00', @end_date_time = '2017-02-05 13:30:00';

\! echo "SELECT * FROM hh_power, date_time, tariff, impose_tariff INTO OUTFILE /home/silvio/mysql/out/hh_power_mg75hh.csv"
SELECT hp.hh_id, hp.date_time_utc, dt.date_time_act, hp.hh_load_kw, hp.hh_solar_kw, tf.tariff_code,
tf.price_kwh, tf.feedin_kwh
FROM hh_power hp, date_time dt, tariff tf, impose_tariff it
WHERE hp.date_time_utc = dt.date_time_utc
AND DATE(dt.date_time_act) = it.date_act
AND it.tariff_code = tf.tariff_code
AND TIME(dt.date_time_act) = tf.time_act
AND (hp.date_time_utc >= @start_date_time AND hp.date_time_utc <= @end_date_time)
ORDER BY hp.hh_id, hp.date_time_utc
INTO OUTFILE '/home/silvio/mysql/out/hh_power_mg75hh.csv'
COLUMNS TERMINATED BY ','
;

\! echo "SELECT * FROM mg_power, date_time, tariff, impose_tariff INTO OUTFILE /home/silvio/mysql/out/mg_power_mg75hh.csv"
SELECT mp.mg_code, mp.date_time_utc, dt.date_time_act, mp.mg_load_kw, mp.mg_solar_kw, tf.tariff_code,
tf.price_kwh, tf.feedin_kwh
FROM mg_power mp, date_time dt, tariff tf, impose_tariff it
WHERE mp.date_time_utc = dt.date_time_utc
AND DATE(dt.date_time_act) = it.date_act
AND it.tariff_code = tf.tariff_code
AND TIME(dt.date_time_act) = tf.time_act
AND (mp.date_time_utc >= @start_date_time AND mp.date_time_utc <= @end_date_time)
ORDER BY mp.mg_code, mp.date_time_utc
INTO OUTFILE '/home/silvio/mysql/out/mg_power_mg75hh.csv'
COLUMNS TERMINATED BY ','
;

/*****************************************************************************/

\! echo "INSERT INTO mg_feed SELECT mg_code SUM(*) FROM hh_feed, mg_hh"
INSERT INTO mg_feed
SELECT mg_code, date_time_utc, sum(hh_bess_chrg_kwh), sum(hh_bess_dchrg_kwh), sum(hh_load_kwh), 
sum(hh_import_kwh), sum(hh_export_kwh), sum(hh_net_kwh), sum(hh_solar_kwh)
FROM hh_feed, mg_hh
WHERE hh_feed.hh_id = mg_hh.hh_id
AND mg_code = 'MG75HH'
AND (date_time_utc >= @start_date_time AND date_time_utc <= @end_date_time)
GROUP BY mg_code, date_time_utc
;

\! echo "SELECT * FROM mg_feed, date_time, tariff, impose_tariff INTO OUTFILE /home/silvio/mysql/out/mg_feed_mg75hh.csv"
SELECT mf.mg_code, mf.date_time_utc, dt.date_time_act, mf.mg_bess_chrg_kwh, mf.mg_bess_dchrg_kwh,
mf.mg_load_kwh, mf.mg_import_kwh, mf.mg_export_kwh, mf.mg_net_kwh, mf.mg_solar_kwh, tf.tariff_code, 
tf.price_kwh, tf.feedin_kwh
FROM mg_feed mf, date_time dt, tariff tf, impose_tariff it
WHERE mf.date_time_utc = dt.date_time_utc
AND DATE(dt.date_time_act) = it.date_act
AND it.tariff_code = tf.tariff_code
AND TIME(dt.date_time_act) = tf.time_act
AND (mf.date_time_utc >= @start_date_time AND mf.date_time_utc <= @end_date_time)
ORDER BY mf.mg_code, mf.date_time_utc
INTO OUTFILE '/home/silvio/mysql/out/mg_feed_mg75hh.csv'
COLUMNS TERMINATED BY ','
;