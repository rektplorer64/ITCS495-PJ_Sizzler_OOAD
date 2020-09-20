CREATE OR REPLACE VIEW "EmployeeView"
AS
SELECT "E"."employeeId",
       "firstname",
       "surname",
       "nickname",
       "birthdate",
       "age",
       "phoneNumbers",
       "email",
       replace('{' ||
            CASE WHEN "C"."employeeId" IS NOT NULL THEN 'Chef,' ELSE '' END ||
            CASE WHEN "BM"."employeeId" IS NOT NULL THEN 'Branch Manager,' ELSE '' END ||
            CASE WHEN "C2"."employeeId" IS NOT NULL THEN 'Cashier,' ELSE '' END ||
            CASE WHEN "KM"."employeeId" IS NOT NULL THEN 'Kitchen Manager,' ELSE '' END ||
            CASE WHEN "DM"."employeeId" IS NOT NULL THEN 'Delivery Man,' ELSE '' END ||
            CASE WHEN "W"."employeeId" IS NOT NULL THEN 'Waiter,' ELSE ''  END ||
            CASE WHEN "KP"."employeeId" IS NOT NULL THEN 'Kitchen Porter' ELSE '' END ||
       '}', ',}', '}')::text[] "position",
       "educationLevel",
       "branchId"                                                       "workAtBranch"
FROM (
         SELECT "E"."employeeId",
                "firstname",
                "surname",
                "nickname",
                "birthdate",
                "age",
                array_agg("telephoneNo") "phoneNumbers",
                "email",
                "E3"."nameEnglish"       "educationLevel",
                "branchId"
         FROM "Employee" "E"
                  JOIN "EmployeeTelephone" "ET" ON "E"."employeeId" = "ET"."employeeId"
                  JOIN "EducationLevelRef" "E3" ON "E"."educationLevelId" = "E3"."educationLevelId"
         GROUP BY "E"."employeeId", "firstname", "surname", "nickname", "email", "nameEnglish"
     ) "E"

         LEFT JOIN "Chef" "C" ON "E"."employeeId" = "C"."employeeId"
         LEFT JOIN "BranchManager" "BM" ON "E"."employeeId" = "BM"."employeeId"
         LEFT JOIN "Cashier" "C2" ON "E"."employeeId" = "C2"."employeeId"
         LEFT JOIN "KitchenManager" "KM" ON "E"."employeeId" = "KM"."employeeId"
         LEFT JOIN "DeliveryMan" "DM" ON "E"."employeeId" = "DM"."employeeId"
         LEFT JOIN "KitchenPorter" "KP" ON "E"."employeeId" = "KP"."employeeId"
         LEFT JOIN "Waiter" "W" ON "E"."employeeId" = "W"."employeeId";


SELECT ('{' ||
        CASE WHEN "W"."employeeId" IS NOT NULL THEN 'A,' ELSE '' END ||
        CASE WHEN "W"."employeeId" IS NOT NULL THEN 'asdsa' ELSE '' END
            || '}')::text[] FROM "Waiter" "W"