/* Lists all entrysteps available for a particular integration type */

\prompt 'Please enter the clearinghouse', clearinghouse
\prompt 'Please enter the category [deposit; withdraw; accountselector]', category
\prompt 'Please enter the name', name

\set QUIET ON

\pset expanded off


SELECT entrysteps.entrystepid,
       entrysteps.identifier,
       entrysteps.name,
       clearinghouses.name AS cleairnghouse, 
       workertypes.name AS type,
       entrysteps.standard,
       entrysteps.disabled,
       entrysteps.allowdirectdebit,
       entrysteps.preferformandateregistration,
       entrysteps.standardformandateregistration,
       entrysteps.isopenbanking,
       entrysteps.supportspnp
  FROM entrysteps
  JOIN clearinghouses ON clearinghouses.clearinghouseID = entrysteps.clearinghouseID
  JOIN ordersteptypes ON ordersteptypes.ordersteptypeid = entrysteps.ordersteptypeid
  JOIN workertypes ON workertypes.workertypeid = ordersteptypes.ordertypeid
 WHERE clearinghouses.Name = :'clearinghouse'
   AND category = :'category'
   AND entrysteps.name ILIKE '%' || :'name' || '%'
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'entrystep_management_overview');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
