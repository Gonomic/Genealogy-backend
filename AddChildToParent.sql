CREATE DEFINER=`root`@`%` PROCEDURE `AddChildToParent`(IN Parent INT, IN Child INT)
BEGIN

	-- ----------------------------------------------------------------------------------------------------------------------------------------------
    -- Author: 	Frans Dekkers (GoNomics)
    -- Date:	31-01-2020
    -- -----------------------------------
    -- Prurpose of this Sproc:
    -- Add a child to a parent
    -- 
    -- Parameters of this Sproc:
    -- 'Parent'= The person to add the child to
    -- 'Child'= The person to add as child
    -- 
    -- High level flow of this Sproc:
    -- => Simply add a record to table relations which ties one person as a child to another person as a father
    --   
    -- Note:	None
    --		
    -- TODO's:
    -- => 01/02/2020 -> Determine if the parent is a father or mother and then add the correct relation
    -- => 01/02/2020 -> Add logic for if the transaction fails (take one of the other Sprocs as example)
    -- ----------------------------------------------------------------------------------------------------------------------------------------------
    
    DECLARE CompletedOk INT;
    DECLARE NewTransNo INT;
    DECLARE TransResult INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SET CompletedOk = 2;
		INSERT INTO humans.testlog 
			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), ". ", "Error occured in SPROC: AddChildToParrent(). Rollback executed. Not completed OK (NOK) for parent= ", IFNULL(Parent, 'null'), " and child= ", IFNULL(Child, 'null')),
				TestLogDateTime = NOW();
		SELECT "NOK";
	END;
	
    SET CompletedOk = true;
    SET TransResult = 0;
    SET NewTransNo = GetTranNo("AddChildToParent");
    
      
    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, ''),
							 '. Start SPROC: AddChildToParent(). Add a child to a parent. Parent= ', IFNULL(Parent, 'null'), '. Child= ', IFNULL(Child, 'null')),
			TestLogDateTime = NOW();
    
	INSERT INTO relations (RelationName, RelationPerson, RelationWithPerson) 
	VALUES (1, Parent, Child );
   
	INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
			'. TransResult= ', IFNULL(TransResult, ''),
			'. End SPROC: AddChildToParent(). Added child: ', IFNULL(Child, 'null'), 'to parent: ', IFNULL(Parent, 'null')),
			TestLogDateTime = NOW();

SELECT 'OK';
   
END