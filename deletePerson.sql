CREATE DEFINER=`root`@`%` PROCEDURE `deletePerson`(IN `PersonIdIn` INT, IN MotherIdIn INT, IN FatherIdIn INT, IN PartnerIdIn INT, TimestampIn DATETIME)
    SQL SECURITY INVOKER
    COMMENT 'To delete a Person from the database, incl. links from Family to this Person.'
BEGIN

	-- CompletedOk defines the result of a database transaction, like this:

    -- 0 = Transaction finished without problems.

    -- 1 = Transaction aborted due to Person's details changed in the mean time

    -- 2 = Transaction aborted due to problems during update and rollback performed

    -- ...

    DECLARE CompletedOk int;

    -- NewTransNo is autonumber counter fetched from a seperate table and used for logging in a seperate log table
	DECLARE NewTransNo int;

    -- TransResult is used to count the number of seperate database operations and rissen with each step
	DECLARE TransResult int;

    -- RecCount is used to count the number of related records in depended tables.
	DECLARE RecCount int;

	DECLARE MessageText CHAR;

	DECLARE ReturnedSqlState INT;

	DECLARE MySQLErrNo INT;
        
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
 	BEGIN

		GET CURRENT DIAGNOSTICS CONDITION 1 MessageText = message_text, ReturnedSqlState = RETURNED_SQLSTATE, MySqlErrNo = MYSQL_ERRNO;
        
		ROLLBACK;

		SET CompletedOk = 2;

		INSERT INTO humans.testlog 

			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), " SPROC deletePerson(). Error occured()=", 
								 IFNULL(MessageText, "null"), "/State=", IFNULL(ReturnedSqlState, "null"), "/ErrNo=", IFNULL(MySqlErrNo, "null"), "). Rollback executed. CompletedOk= ", CompletedOk),
								 TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;

    SET CompletedOk = 0;

    SET TransResult = 0;

    SET NewTransNo = GetTranNo("deletePerson");

    -- Schrijf start van deze SQL transactie naar log
    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Start SPROC: deletePerson() voor persoon met ID= ', PersonIdIn),
		TestLogDateTime = NOW();
  
  transactionBody:BEGIN

	START TRANSACTION;
        
    IF RecordHasBeenChangedBySomebodyElse(PersonIdIn, TimeStampIn) THEN

	    SET CompletedOk = 1;

	    INSERT INTO humans.testLog 

		    SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), ". TransResult= ", TransResult, ". Records has been changed in mean time by somebody else. Deletion aborted."),

			    TestLogDateTime = NOW();

	    SELECT CompletedOk, 'RecordWasChangedBySomeBodyElse';

	    LEAVE transactionBody;

    END IF;


	-- First delete parents and partner
    -- Mother
	DELETE FROM humans.relations 
		WHERE RelationPerson = PersonIdIn
			AND RelationWithPerson = MotherIdIn
			AND RelationName = fGetRelationId("Moeder");
	SET TransResult = TransResult + 1;
	INSERT INTO humans.testlog
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ', Transresult= ', IFNULL(TransResult, 'null'), '. Moeder relatie van moeder met ID= ', IFNULL(MotherIdIn, 'null'), ' en Persoon met ID= ', IFNULL(PersonIdIn, 'null'), ' is verwijderd uit de database als deze in de database bestond.'),
			TestLogDateTime = NOW();

    -- Father
	DELETE FROM humans.relations 
		WHERE RelationPerson = PersonIdIn
			AND RelationWithPerson = FatherIdIn
			AND RelationName = fGetRelationId("Vader");
	SET TransResult = TransResult + 1;
	INSERT INTO humans.testlog
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ', TransResult= ', IFNULL(TransResult, 'null'), '. Vader relatie van vader met ID= ', IFNULL(FatherIdIn, 'null'), ' en Persoon met ID= ', IFNULL(PersonIdIn, 'null'), ' is verwijderd uit de database als deze in de database bestond.'),
			TestLogDateTime = NOW();    
    
    -- Partner
	DELETE FROM humans.relations 
		WHERE RelationPerson = PersonIdIn
		AND RelationWithPerson = PartnerIdIn
		AND RelationName = fGetRelationId("Partner");
	DELETE FROM humans.relations 
		WHERE RelationPerson = PartnerIdIn
        AND RelationWithPerson = PersonIdIn
		AND RelationName = fGetRelationId("Partner");
	SET TransResult = TransResult + 1;
	INSERT INTO humans.testlog
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ', TransResult= ', IFNULL(TransResult, 'null'), '. Partner relatie van partner met ID= ', IFNULL(PartnerIdIn, 'null'), ' en persoon met ID= ', IFNULL(PersonIdIn, 'null'), ' is verwijderd uit de database.'),
			TestLogDateTime = NOW();

    -- Finaly delete Person 
    DELETE FROM persons
		WHERE PersonID = PersonIdIn;

    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ', TransResult= ', IFNULL(TransResult, 'null'), '. Persoon met ID= ', IFNULL(PersonIdIn, 'null'), ' is met al zijn relaties verwijderd uit de database.'),
		TestLogDateTime = NOW();

    SELECT CompletedOk, "DeletionHasFinished";

    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. SPROC DeletePerson afgerond. CompletedOk= ', IFNULL(CompletedOk, 'null')),
		TestLogDateTime = NOW();
	
    COMMIT;

END ;

END