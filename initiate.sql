/*Creates TEMP Table supportsqlaliases and inserts Valies
  This file must be added in psqlrc file*/

DROP TABLE supportsqlaliases;
CREATE TEMP TABLE supportsqlaliases(
  category text[3] NOT NULL,
  aliasname character varying NOT NULL,
  comment text
);
\COPY supportsqlaliases(category, aliasname, comment) FROM '/Users/benjaminschembri/Trustly/Atom/SupportSQLRepository/supportsqlaliases.csv' DELIMITER ',' CSV HEADER --!! THE PATH NEEDS TO CHANGE TO GIT REPOSITORY OR GOOGLE DRIVE


--Function Populating SupportSQLAliases Table
CREATE OR REPLACE FUNCTION pg_temp.add_alias(_category text[3], _aliasname character varying, _comment text)
  RETURNS boolean
  LANGUAGE plpgsql
  AS $supportfunction$
  DECLARE
  _OK boolean;
  BEGIN
  INSERT INTO supportsqlaliases
    (category, aliasname, comment)
  VALUES
    (_category, _aliasname, _comment)
  RETURNING TRUE INTO STRICT _OK;
  --Once the tuple is added, the new data in SupportSQLAliases is saved to CSV file.
  COPY supportsqlaliases(category, aliasname, comment) TO '/Users/benjaminschembri/Trustly/Atom/SupportSQLRepository/supportsqlaliases.csv' DELIMITER ',' CSV HEADER; --!! THE PATH NEEDS TO CHANGE TO GIT REPOSITORY OR GOOGLE DRIVE
  RAISE NOTICE 'NOTICE_ALIAS_CREATED Category %, AliasName %, Comment %',_Category, _aliasname,_comment;
  RETURN TRUE;
  END;
  $supportfunction$
;

--Function Removing Data from SupportSQLAliases Table
CREATE OR REPLACE FUNCTION pg_temp.remove_alias(_aliasname character varying)
  RETURNS boolean
  LANGUAGE plpgsql
  AS $supportfunction$
  DECLARE
  _OK boolean;
  BEGIN
  DELETE FROM supportsqlaliases
    WHERE AliasName = _aliasname
  RETURNING TRUE INTO STRICT _OK;
  --Once the tuple is removed, the new data in SupportSQLAliases is saved to CSV file.
  COPY supportsqlaliases(category, aliasname, comment) TO '/Users/benjaminschembri/Trustly/Atom/SupportSQLRepository/supportsqlaliases.csv' DELIMITER ',' CSV HEADER; --!! THE PATH NEEDS TO CHANGE TO GIT REPOSITORY OR GOOGLE DRIVE
  RAISE NOTICE 'NOTICE_ALIAS_REMOVED AliasName %', _aliasname;
  RETURN TRUE;
  END;
  $supportfunction$
;
