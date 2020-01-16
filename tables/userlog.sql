-- Create temporary table to import data from useraccesslog.csv in Support Shared Google Drive
\cd :local_path_supportsqlprocedures/procedures
\set QUIET ON
DROP TABLE IF EXISTS pg_temp.SupportSQL_UserLog;
CREATE TEMP TABLE SupportSQL_UserLog(username text, datestamp text, Procedure text);
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
