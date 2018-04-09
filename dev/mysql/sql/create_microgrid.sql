/****************************************************************************** 
 * create_microgrid.sql
 * SQL script for creating tables in sagrid database (microgrid project):
 * mg_feed
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid

\! echo "CREATE TABLE hh_feed"
DROP TABLE IF EXISTS hh_feed;
CREATE TABLE hh_feed (
	hh_id bigint unsigned not null,
	date_time_utc datetime not null,
	hh_bess_chrg_kwh float not null,
	hh_bess_dchrg_kwh float not null,
	hh_load_kwh float not null,
	hh_import_kwh float not null,
	hh_export_kwh float not null,
	hh_net_kwh float not null,
	hh_solar_kwh float not null
);
DESCRIBE hh_feed;

\! echo "CREATE TABLE mg_feed"
DROP TABLE IF EXISTS mg_feed;
CREATE TABLE mg_feed (
	mg_code char(8) not null,
	date_time_utc datetime not null,
	mg_bess_chrg_kwh float not null,
	mg_bess_dchrg_kwh float not null,
	mg_load_kwh float not null,
	mg_import_kwh float not null,
	mg_export_kwh float not null,
	mg_net_kwh float not null,
	mg_solar_kwh float not null
);
DESCRIBE mg_feed;

\! echo "CREATE TABLE mg_hh and INDEXES"
DROP TABLE IF EXISTS mg_hh;
CREATE TABLE mg_hh (
	mg_code char(8) not null,
	hh_id bigint unsigned not null
);
CREATE UNIQUE INDEX mghhidx
ON mg_hh (mg_code, hh_id);
DESCRIBE mg_hh;

\! echo "CREATE TABLE hh_energy and INDEXES"
DROP TABLE IF EXISTS hh_energy;
CREATE TABLE hh_energy (
	hh_id bigint unsigned not null,
	date_time_utc datetime not null,
	hh_solar_kwh float not null,
	hh_bess_chrg_kwh float not null,
	hh_load_kwh float not null,
	hh_grid_kwh float not null,
	hh_intrpl boolean not null
);
CREATE INDEX hhidx
ON hh_energy (hh_id);
CREATE INDEX dtmidx
ON hh_energy (date_time_utc);
CREATE UNIQUE INDEX hhdtmidx
ON hh_energy (hh_id, date_time_utc);
DESCRIBE hh_energy;

\! echo "CREATE TABLE hh_power and INDEXES"
DROP TABLE IF EXISTS hh_power;
CREATE TABLE hh_power (
	hh_id bigint unsigned not null,
	date_time_utc datetime not null,
	hh_solar_kw float not null,
	hh_bess_chrg_kw float not null,
	hh_load_kw float not null,
	hh_grid_kw float not null,
	hh_intrpl boolean not null
);
CREATE INDEX hhidx
ON hh_power (hh_id);
CREATE INDEX dtmidx
ON hh_power (date_time_utc);
CREATE UNIQUE INDEX hhdtmidx
ON hh_power (hh_id, date_time_utc);
DESCRIBE hh_power;

\! echo "CREATE TABLE mg_energy and INDEXES"
DROP TABLE IF EXISTS mg_energy;
CREATE TABLE mg_energy (
	mg_code char(8) not null,
	date_time_utc datetime not null,
	mg_solar_kwh float not null,
	mg_bess_chrg_kwh float not null,
	mg_load_kwh float not null,
	mg_grid_kwh float not null
);
CREATE UNIQUE INDEX mgdtmidx
ON mg_energy (mg_code, date_time_utc);
DESCRIBE mg_energy;

\! echo "CREATE TABLE mg_power and INDEXES"
DROP TABLE IF EXISTS mg_power;
CREATE TABLE mg_power (
	mg_code char(8) not null,
	date_time_utc datetime not null,
	mg_solar_kw float not null,
	mg_bess_chrg_kw float not null,
	mg_load_kw float not null,
	mg_grid_kw float not null
);
CREATE UNIQUE INDEX mgdtmidx
ON mg_power (mg_code, date_time_utc);
DESCRIBE mg_power;
