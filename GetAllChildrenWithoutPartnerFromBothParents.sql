DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `GetAllChildrenWithoutPartnerFromBothParents`(IN `Father` int(11), IN `Mother` int(11))
    SQL SECURITY INVOKER
    COMMENT 'To get all children from a two specific parents and without the partner'
BEGIN

SELECT DISTINCT * FROM persons 
	WHERE PersonID IN 
	(SELECT RelationPerson FROM relations
		WHERE (RelationWithPerson = Father OR RelationWithPerson = Mother)
        AND (RelationName = 1 OR RelationName = 2));
  
#  SELECT DISTINCT
#
#    CONCAT(Children.PersonGivvenName, ' ', Children.PersonFamilyName) AS 'Naam kind'
#
 # FROM relations AllRelations

    #   Get all records from RELATIONS from specific persons who are either father or mother

 #   INNER JOIN relationnames IsChild

 #     ON AllRelations.RelationName = IsChild.RelationNameID

 #     AND (IsChild.RelationnameName = 'Vader' AND AllRelations.RelationWithPerson = Father)

 #     OR (IsChild.RelationnameName = 'Moeder' AND AllRelations.RelationWithPerson = Mother)

    #   Get all the children from these specific persons who are either father or mother

 #   INNER JOIN persons Children

 #     ON AllRelations.RelationPerson = Children.PersonID

  # Get all partners of the above found children

 # ORDER BY Children.PersonDateOfBirth;

END$$
DELIMITER ;
