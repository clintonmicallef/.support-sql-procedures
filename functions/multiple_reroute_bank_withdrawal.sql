--Enables the functionality to reroute to specific sending account by rerouting multiple times (must be available route)

CREATE OR REPLACE FUNCTION pg_temp.multiple_reroute_bank_withdrawal(_DestinationSendingBankAccount text, _bankwithdrawalid bigint)
RETURNS boolean
LANGUAGE plpgsql

AS $function$

DECLARE
  _CheckBankwithdrawalstateID integer;
  _currentsendingbankaccount text;

BEGIN
  SELECT BankAccounts.Ecosysaccount
    INTO _currentsendingbankaccount
    FROM Bankwithdrawals
    JOIN BankAccounts ON BankAccounts.BankAccountID = Bankwithdrawals.SendingBankAccountID
   WHERE Bankwithdrawals.BankwithdrawalID = _BankWithdrawaLID;

  --Access to use this function granted only to 2ndline agents
  IF NOT EXISTS(
    SELECT 1
      FROM pg_auth_members
      JOIN pg_roles member ON member.oid = pg_auth_members.member
      JOIN pg_roles role ON role.oid=pg_auth_members.roleid
     WHERE role.rolname = 'support_second_line'
       AND member.rolname = session_user
     ) THEN
         RAISE EXCEPTION 'No Function access. 2ndline access only';
  END IF;

  --Make sure the destination account entered is different that the current sending account
  IF _DestinationSendingBankAccount = _currentsendingbankaccount THEN
      RAISE EXCEPTION 'DestinationSendingBankAccount % is the same as currentsendingbankaccount %', _DestinationSendingBankAccount, _currentsendingbankaccount;
  END IF;

  --Ensure destination account is a candidate
  IF NOT EXISTS (
    SELECT 1
      FROM (
            SELECT (Get_Sending_Bank_Account_Candidates(_UserID := BankWithdrawals.UserID,
                                                      _Currency := BankWithdrawals.Currency,
                                                        _Amount := BankWithdrawals.Amount,
                                            _BankWithdrawalType := BankWithdrawalTypes.BankWithdrawalType,
                                                  _ToBankNumber := BankNumbers.BankNumber,
                                             _ToClearingHouseID := BankWithdrawals.ToClearingHouseID,
                                            _SendingBankAccount := NULL)).*
              FROM BankWithdrawals
              JOIN BankWithdrawalTypes ON (BankWithdrawalTypes.BankWithdrawalTypeID = BankWithdrawals.BankWithdrawalTypeID)
              JOIN BankNumbers ON (BankNumbers.BankNumber = BankWithdrawals.ToBankNumber AND BankNumbers.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
              JOIN Banks ON (Banks.BankID = BankNumbers.BankID)
              JOIN ClearingHouses ON (ClearingHouses.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
             WHERE BankWithdrawalID = _BankWithdrawaLID
           ) AS Candidates
     WHERE Candidates.WithdrawalsEnabled AND
           Candidates.AllowWithdrawals AND
           Candidates.BankAccountCutOffTimes AND
           Candidates.BalanceNotExceeded AND
           Candidates.MaxAmount AND
           Candidates.Whitelist AND
           Candidates.NotAvoidRoute
           AND candidates.ecosysaccount = _DestinationSendingBankAccount
     ORDER BY Candidates.SameCurrency DESC,
           Candidates.BankNumberPreferredRoute DESC,
           Candidates.BankPreferredRoute DESC,
           Candidates.SendingBankAccount DESC NULLS LAST,
           Candidates.ClearingHouseBankAccount DESC NULLS LAST,
           Candidates.BankGroup DESC NULLS LAST,
           Candidates.IntraBank DESC NULLS LAST,
           Candidates.Priority ASC NULLS LAST,
           Candidates.Balance DESC NULLS LAST
     LIMIT 5
   )THEN
      RAISE EXCEPTION '% not an available route', _DestinationSendingBankAccount;
  END IF;

  SELECT BankwithdrawalstateID
    INTO _CheckBankwithdrawalstateID
    FROM BankWithdrawals
   WHERE BankWithdrawals.BankWithdrawalID = _BankWithdrawaLID;

    IF _CheckBankwithdrawalstateID = 1 /*Bankwithdrawal in QUEUED*/ THEN
      WHILE (_currentsendingbankaccount <> _DestinationSendingBankAccount AND _CheckBankwithdrawalstateID = 1)
      LOOP
          PERFORM Reroute_Bank_Withdrawal(
                      _BankWithdrawalID := _BankWithdrawalID,
                      _CurrentSendingBankAccount := _CurrentSendingBankAccount,
                      _PermanentReroute := FALSE
                    );

          SELECT BankAccounts.Ecosysaccount
            INTO _currentsendingbankaccount
            FROM Bankwithdrawals
            JOIN BankAccounts ON BankAccounts.BankAccountID = Bankwithdrawals.SendingBankAccountID
           WHERE Bankwithdrawals.BankwithdrawalID = _BankWithdrawaLID;

          SELECT BankwithdrawalstateID
            INTO _CheckBankwithdrawalstateID
            FROM BankWithdrawals
           WHERE BankWithdrawals.BankWithdrawalID = _BankWithdrawaLID;
      END loop;

    ELSE RAISE EXCEPTION 'BankWithdrawal is not in Queued State';
    END IF;

  RAISE NOTICE 'New SendingBankAccountID: %', _currentsendingbankaccount;

RETURN true;
END;
$function$
;
