/******************************************************************************
 * sim_output.sql
 * SQL script for loading output from simulation runs into database
 * (microgrid project).
 *****************************************************************************/

\! echo "USE sagrid"
USE sagrid

\! echo "CREATE TABLE sim_output_qp"
DROP TABLE IF EXISTS sim_output_qp;
CREATE TABLE sim_output_qp (
	sim_run char(16) not null,
	mg_hh_code char(8) not null,
	date_time_act datetime not null,
	bess_chrg_kw float not null,
	bess_dchrg_kw float not null,
	load_kw float not null,
	solar_kw float not null,
	grid_power_kw float not null,
	grid_power_cost float not null,
	bess_soc_kwh float not null
);
CREATE INDEX simqpidx
ON sim_output_qp (sim_run, mg_hh_code, date_time_act);
DESCRIBE sim_output_qp; 

\! echo "CREATE TABLE sim_output_lp"
DROP TABLE IF EXISTS sim_output_lp;
CREATE TABLE sim_output_lp (
	sim_run char(16) not null,
	mg_hh_code char(8) not null,
	date_time_act datetime not null,
	bess_chrg_kw float not null,
	bess_dchrg_kw float not null,
	load_kw float not null,
	solar_kw float not null,
	power_imp_kw float not null,
	power_exp_kw float not null,
	power_cost float not null,
	power_rev float not null,
	bess_soc_kwh float not null
);
CREATE INDEX simlpidx
ON sim_output_lp (sim_run, mg_hh_code, date_time_act);
DESCRIBE sim_output_lp; 

/*****************************************************************************/

\! echo "LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/miqp_oneprd_75HH.csv' INTO TABLE sim_output_qp"
LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/miqp_oneprd_75HH.csv'
INTO TABLE sim_output_qp
COLUMNS TERMINATED BY ','
(sim_run, mg_hh_code, @date_time_act, bess_chrg_kw, bess_dchrg_kw, load_kw, solar_kw, grid_power_kw, grid_power_cost, bess_soc_kwh)
SET date_time_act = STR_TO_DATE( @date_time_act, '%d-%b-%Y %T')
;

\! echo "LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/milp_oneprd_75HH.csv' INTO TABLE sim_output_lp"
LOAD DATA LOCAL INFILE '/home/silvio/mysql/in/milp_oneprd_75HH.csv'
INTO TABLE sim_output_lp
COLUMNS TERMINATED BY ','
(sim_run, mg_hh_code, @date_time_act, bess_chrg_kw, bess_dchrg_kw, load_kw, solar_kw, power_imp_kw, power_exp_kw, power_cost, power_rev, bess_soc_kwh)
SET date_time_act = STR_TO_DATE( @date_time_act, '%d-%b-%Y %T')
;

/*****************************************************************************/

\! echo "SELECT SUM(grid_power_kw) FROM sim_output_qp INTO FILE '/home/silvio/mysql/out/sim_output_QP75HHONEPRD.csv'"
SELECT sim_run, date_time_act, SUM(grid_power_kw)
FROM sim_output_qp
WHERE sim_run = 'QP75HHONEPRD'
GROUP BY sim_run, date_time_act
ORDER BY sim_run, date_time_act
INTO OUTFILE '/home/silvio/mysql/out/sim_output_QP75HHONEPRD.csv'
COLUMNS TERMINATED BY ','
;

\! echo "SELECT SUM(power_imp_kw), SUM(power_exp_kw) FROM sim_output_lp INTO FILE '/home/silvio/mysql/out/sim_output_QP75HHONEPRD.csv'"
SELECT sim_run, date_time_act, SUM(power_imp_kw), SUM(power_exp_kw)
FROM sim_output_lp
WHERE sim_run = 'LP75HHONEPRD'
GROUP BY sim_run, date_time_act
ORDER BY sim_run, date_time_act
INTO OUTFILE '/home/silvio/mysql/out/sim_output_LP75HHONEPRD.csv'
COLUMNS TERMINATED BY ','
;


