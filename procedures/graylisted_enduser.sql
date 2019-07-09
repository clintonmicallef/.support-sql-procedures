/* Information on whether an Enduser has failed deposits (graylisted) */

\prompt 'Please enter a PersonID', personid

\pset expanded off

SELECT transfers.transferid,
       transfers.orderid,
       transfersystems.name AS transfersystem,
       users.username AS "user",
       transfers.amount,
       transfers.currency,
       transfertypes.name AS transfertype,
       transferstates.name AS transferstate,
       transfers.datestamp::timestamp(0),
       orders.enduserid,
       transfers.triggeredpending::timestamp(0),
       transfers.triggeredcredit::timestamp(0),
       transfers.triggeredcancel::timestamp(0),
       transfers.triggereddebit::timestamp(0),
       eventnamechains.name AS eventnamechain,
       forgivenfailedtransfers.datestamp::timestamp(0) AS forgiven,
       forgivenfailedtransfers.datestamp IS NULL AND (transfersystems.name = ANY (ARRAY['DirectRouting'::text, 'Autogiro'::text])) AS showforgivebutton,
       eventnamechainbalances.personid AS personid,
       (CASE WHEN forgivenfailedvolumes.PersonID = eventnamechainbalances.personid AND forgivenfailedvolumes.UserID IS NOT NULL THEN 'FORGIVEN_LOCALLY'
             WHEN forgivenfailedvolumes.PersonID = eventnamechainbalances.personid AND forgivenfailedvolumes.UserID IS NULL THEN 'FORGIVEN_GLOBALLY'
             ELSE 'GRAYLISTED' END) as BlockType
  FROM transfers
  JOIN transfersystems ON (transfersystems.transfersystemid = transfers.transfersystemid)
  JOIN eventnamechainbalances ON (eventnamechainbalances.eventnamechainbalanceid = transfers.eventnamechainbalanceid)
  JOIN eventnamechains ON (eventnamechains.eventnamechainid = eventnamechainbalances.eventnamechainid)
  JOIN orders ON (orders.orderid = transfers.orderid)
  JOIN transferstates ON (transferstates.transferstateid = transfers.transferstateid)
  JOIN transfertypes ON (transfertypes.transfertypeid = transfers.transfertypeid)
  JOIN users ON (users.userid = transfers.userid)
  LEFT JOIN forgivenfailedtransfers ON (forgivenfailedtransfers.transferid = transfers.transferid)
  LEFT JOIN forgivenfailedvolumes ON (forgivenfailedvolumes.PersonID = eventnamechainbalances.PersonID)
 WHERE transfers.transfertypeid = 1 AND transfers.transferstateid = 8
   AND eventnamechainbalances.personid = ANY(Get_Related_PersonIDs(:'personid'))
 ORDER BY transfers.datestamp DESC;
