/*Checks whether a connection between one Processing Account and another exists*/

\prompt 'Please enter the 1st ProcessingAccount', processingaccount1
\prompt 'Please enter the 2nd ProcessingAccount', processingaccount2

\pset expanded off

SELECT m2m.fromuserid, m2m.touserid, fu.username AS fromuser, tu.username AS touser, m2m.datestamp::timestamp(0)
  FROM MerchantToMerchantUsers m2m
  JOIN Users fu ON (fu.UserID = m2m.FromUserID)
  JOIN Users tu ON (tu.UserID = m2m.ToUserID)
 WHERE m2m.ToUserID = Get_UserID(:'processingaccount1')
    OR m2m.ToUserID = Get_UserID(:'processingaccount2');
