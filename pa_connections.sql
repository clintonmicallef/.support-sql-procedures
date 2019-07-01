/*Checks whether a connection of processing accounts for one Processing Account exists*/

\prompt 'Please enter the ProcessingAccount', processingaccount

\pset expanded off

SELECT m2m.fromuserid, m2m.touserid, fu.username AS fromuser, tu.username AS touser, m2m.datestamp::timestamp(0)
  FROM MerchantToMerchantUsers m2m
  JOIN Users fu ON (fu.UserID = m2m.FromUserID)
  JOIN Users tu ON (tu.UserID = m2m.ToUserID)
 WHERE m2m.FromUserID = Get_UserID(:'processingaccount')
    OR m2m.ToUserID = Get_UserID(:'processingaccount');
