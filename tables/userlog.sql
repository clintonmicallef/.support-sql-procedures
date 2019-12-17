-- Create temporary table for user access log stats
\cd :local_path_supportsqlprocedures/procedures
\set QUIET ON
DROP TABLE IF EXISTS pg_temp.SupportSQL_UserLog;
CREATE TEMP TABLE SupportSQL_UserLog(user text, datestamp timestamp, Procedure text);
