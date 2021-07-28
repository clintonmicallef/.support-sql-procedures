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
       entrysteps.disabled::timestamp(0),
       entrysteps.allowdirectdebit,
       entrysteps.preferformandateregistration,
       entrysteps.standardformandateregistration,
       entrysteps.isopenbanking,
       entrysteps.supportspnp,
       NoofOrders.count AS Orderslast12hr
  FROM entrysteps
  JOIN clearinghouses ON clearinghouses.clearinghouseID = entrysteps.clearinghouseID
  JOIN ordersteptypes ON ordersteptypes.ordersteptypeid = entrysteps.ordersteptypeid
  JOIN workertypes ON workertypes.workertypeid = ordersteptypes.ordertypeid
  LEFT JOIN LATERAL(
    SELECT EntrystepID, COUNT(*)
      FROM Orders
     WHERE Orders.datestamp >= now() - interval '12 hours'
       AND Orders.UserID != get_userid('apitest')
     GROUP BY 1
  ) NoofOrders ON NoofOrders.EntrystepID = Entrysteps.EntrystepID
 WHERE clearinghouses.Name = :'clearinghouse'
   AND category = :'category'
   AND entrysteps.name ILIKE '%' || :'name' || '%'
;
