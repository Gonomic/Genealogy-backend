ALTER TABLE `humans`.`persons` 
ADD COLUMN `PersonDateOfBirthStatus` INT NOT NULL DEFAULT 1 COMMENT 'Status must be filled: 1= birthdate is certain, 2 = birthdate is estimated and 3= birthdate was not known' AFTER `Timestamp`,
ADD COLUMN `PersonDateOfDeathStatus` INT NULL COMMENT 'Status can be filled: 1= birthdate is certain, 2 = birthdate is estimated and 3= birthdate was not known' AFTER `PersonDateOfBirthStatus`;
