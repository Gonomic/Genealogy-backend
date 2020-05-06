    going_up: LOOP
    
		INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. =====>> Going up! Getting all ancestors (up until requested ancestor level)'),
						TestLogDateTime = NOW();
        
        IF EXISTS (SELECT RecordId FROM FamilyTree WHERE RecordId = RecordIndex) THEN 
			SELECT PersonsFather, PersonsMother, PersonsPartner INTO @FatherAsNextPerson, @MotherAsNextPerson, @PartnerAsNextPerson FROM FamilyTree WHERE RecordId = RecordIndex;
    
			
            IF ! ISNULL(@MotherAsNextPerson) THEN
				SELECT COUNT(*) FROM FamilyTree WHERE PersonId = @MotherAsNextPerson LIMIT 1 INTO PersonAlreadyInFamilyTree;
				IF PersonAlreadyInFamilyTree = 0 THEN
					INSERT INTO humans.testlog 
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. Begin opslaan data voor persoon met ID= ', IFNULL(@MotherAsNextPerson, 'null')),
						TestLogDateTime = NOW();
					INSERT INTO FamilyTree (PersonId, PersonName, PersonBirth, PersonDeath, PersonIsMale)
						SELECT PersonId, CONCAT(PersonGivvenName, " ", PersonFamilyName), PersonDateOfBirth, PersonDateOfDeath, PersonIsMale FROM persons WHERE persons.PersonId = @MotherAsNextPerson;
					SET pMother = fGetMother(@MotherAsNextPerson);
					SET pFather = fGetFather(@MotherAsNextPerson);
					SET pPartner = fGetPartner(@MotherAsNextPerson);  
					UPDATE FamilyTree SET PersonsFather = pFather, FatherFetched = false, PersonsMother = pMother, MotherFetched=false, PersonsPartner = pPartner, PartnerFetched=false, PersonsParentsArePartners = pPersonsParentsPartners WHERE (PersonId = @MotherAsNextPerson AND RecordId <> 0);
					INSERT INTO humans.testlog
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. Gegevens opgeslagen voor persoon met ID= ', IFNULL(@MotherAsNextPerson, 'null')),
						TestLogDateTime = NOW();
				END IF;
			END IF; 
        
			
			IF ! ISNULL(@FatherAsNextPerson) THEN
				SELECT COUNT(*) FROM FamilyTree WHERE PersonId = @FatherAsNextPerson LIMIT 1 INTO PersonAlreadyInFamilyTree;
				IF PersonAlreadyInFamilyTree = 0 THEN
					INSERT INTO humans.testlog
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. Begin opslaan data voor persoon met ID= ', IFNULL(@FatherAsNextPerson, 'null')),
						TestLogDateTime = NOW();
					INSERT INTO FamilyTree (PersonId, PersonName, PersonBirth, PersonDeath, PersonIsMale)
						SELECT PersonId, CONCAT(PersonGivvenName, " ", PersonFamilyName), PersonDateOfBirth, PersonDateOfDeath, PersonIsMale FROM persons WHERE persons.PersonId = @FatherAsNextPerson;
					SET pMother = fGetMother(@FatherAsNextPerson);
					SET pFather = fGetFather(@FatherAsNextPerson);
					SET pPartner = fGetPartner(@FatherAsNextPerson);  
					UPDATE FamilyTree SET PersonsFather = pFather, FatherFetched = false, PersonsMother = pMother, MotherFetched=false, PersonsPartner = pPartner, PartnerFetched=false, PersonsParentsArePartners = pPersonsParentsPartners WHERE (PersonId = @FatherAsNextPerson AND RecordId <> 0);
					INSERT INTO humans.testlog
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. Gegevens opgeslagen voor persoon met ID= ', IFNULL(@FatherAsNextPerson, 'null')),
						TestLogDateTime = NOW();
				END IF;
			END IF;
        
			
			IF InclusivePartners = 1 THEN
				IF ! ISNULL(@PartnerAsNextPerson) THEN
					SELECT COUNT(*) FROM FamilyTree WHERE PersonId = @PartnerAsNextPerson LIMIT 1 INTO PersonAlreadyInFamilyTree;
					IF PersonAlreadyInFamilyTree = 0 THEN
						INSERT INTO humans.testlog
							SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
							'. TransResult= ', IFNULL(TransResult, ''),
							'. Begin opslaan data voor persoon met ID= ', IFNULL(@PartnerAsNextPerson, 'null')),
							TestLogDateTime = NOW();
						INSERT INTO FamilyTree (PersonId, PersonName, PersonBirth, PersonDeath, PersonIsMale)
							SELECT PersonId, CONCAT(PersonGivvenName, " ", PersonFamilyName), PersonDateOfBirth, PersonDateOfDeath, PersonIsMale FROM persons WHERE persons.PersonId = @PartnerAsNextPerson;
						SET pMother = fGetMother(@PartnerAsNextPerson);
						SET pFather = fGetFather(@PartnerAsNextPerson);
						SET pPartner = fGetPartner(@PartnerAsNextPerson);  
						UPDATE FamilyTree SET PersonsFather = pFather, FatherFetched = false, PersonsMother = pMother, MotherFetched=false, PersonsPartner = pPartner, PartnerFetched=false, PersonsParentsArePartners = pPersonsParentsPartners WHERE (PersonId = @PartnerAsNextPerson AND RecordId <> 0);
						INSERT INTO humans.testlog
							SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
							'. TransResult= ', IFNULL(TransResult, ''),
							'. Gegevens opgeslagen voor persoon met ID= ', IFNULL(@PartnerAsNextPerson, 'null')),
							TestLogDateTime = NOW();
					END IF;
				END IF;
			END IF;
			
		ELSE
			LEAVE going_up;
		END IF;
        
        SET GenerationCounter = GenerationCounter + 1;
        SET RecordIndex = RecordIndex + 1;
     
        IF GenerationCounter >= NumberOfGenerationsToGoUp THEN
			LEAVE going_up;
		END IF;
    END LOOP going_up;