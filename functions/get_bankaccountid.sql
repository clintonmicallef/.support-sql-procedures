-- Get BankAccountID from EcoSysAccount
CREATE OR REPLACE FUNCTION pg_temp.Get_BankAccountID(_EcoSysAccount text)
   RETURNS integer
   LANGUAGE plpgsql
   STABLE
AS $function$
DECLARE
  _BankAccountID integer;
BEGIN

SELECT BankAccounts.BankAccountID INTO _BankAccountID FROM BankAccounts WHERE BankAccounts.EcoSysAccount = _EcoSysAccount;

IF NOT FOUND THEN
  RAISE EXCEPTION 'ERROR_INVALID_BANK_ACCOUNT EcoSysAccount %', _EcoSysAccount;
END IF;

RETURN _BankAccountID;
END;
$function$;
