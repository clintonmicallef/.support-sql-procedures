SELECT (CASE  WHEN (SELECT user) = 'benjaminschembri' THEN (
  SELECT *
    FROM Users
   LIMIT 1
)
ELSE 'Not Authorised' END)
;
