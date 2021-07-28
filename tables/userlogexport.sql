-- Create temporary table for user access log data to be exported to Google Drive (since volatile data)
--This code is now depracted
/*
\cd :local_path_supportsqlprocedures/procedures
\set QUIET ON
DROP TABLE IF EXISTS pg_temp.SupportSQL_UserLogExport;
CREATE TEMP TABLE SupportSQL_UserLogExport(username text, datestamp timestamp, Procedure text);
*/
