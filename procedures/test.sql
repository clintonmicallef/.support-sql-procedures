/* This is a test */

\prompt 'Please enter a Processing Account', processingaccount

SELECT *
  FROM users
 WHERE username = :'processingaccount'
;
