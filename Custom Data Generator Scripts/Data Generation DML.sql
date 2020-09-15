UPDATE "MemberCustomer"
SET "liveNearBranchId" = (SELECT "branchId"
                          FROM "Branch"
                          where "memberCustomerId" = "memberCustomerId"
                          ORDER BY (
                                       SELECT (SELECT random() WHERE g = g AND "branchId" = "branchId")
                                       FROM generate_series(1, 10) g
                                       limit 1
                                   )

                          limit 1)
WHERE "memberCustomerId" NOT IN (
                                 '5d6ea576-5d1a-4de6-8531-f28528fd598a',
                                 '56791212-598f-4b7d-805e-5e7ac69d2f88',
                                 '7f331fbb-4766-4eeb-82d9-c40af58320be',
                                 '07ad35c6-cf7c-43e0-af15-a88d80ad9802',
                                 'c3383057-da58-4814-a1b6-39c97ca67740',
                                 '72a910bd-617b-4fed-93a1-6e10fbae5f95',
                                 'b7a57961-b4ae-46f3-bf63-e20960e9a16b',
                                 '6367080e-ffae-48aa-9581-beb0e2b6c969'
    );


UPDATE "Billing" A
SET "pointExpirationTime"      = '1 year'::interval,
    "pointReceived"            = floor(random() * (1000 - 100 + 1) + 100),
    "involvedMemberCustomerId" = (
        SELECT "memberCustomerId"
        FROM "MemberCustomer"
        WHERE A."billingId" = A."billingId"
        ORDER BY (SELECT (SELECT random() WHERE g = g AND A."billingId" = A."billingId")
                  FROM generate_series(1, 10) g
                  limit 1)
        LIMIT 1
    )
WHERE "timePaid" IS NOT NULL
  AND random() < 0.2;


/**
  Check for member who has involvedMemberCustomerId
 */
SELECT *
FROM "Billing"
WHERE "involvedMemberCustomerId" IS NOT NULL;

-- Update involvedMemberCustomerId with random MemberCustomerId
UPDATE "Billing" A
SET "involvedMemberCustomerId" = (
    SELECT "memberCustomerId"
    FROM "MemberCustomer"
    WHERE A."billingId" = A."billingId"
    ORDER BY (SELECT (SELECT random() WHERE g = g AND "memberCustomerId" = "memberCustomerId")
              FROM generate_series(1, 10) g
              limit 1)
    LIMIT 1
)
WHERE "involvedMemberCustomerId" IS NOT NULL;

-- This WILL NOT WORK. ALL ROWS WILL HAVE a randomly identical "involvedMemberCustomerId" value!!
UPDATE "Billing" A
SET "involvedMemberCustomerId" = (
    SELECT "memberCustomerId"
    FROM "MemberCustomer"
    ORDER BY random()
    LIMIT 1
)
WHERE "involvedMemberCustomerId" IS NOT NULL;

SELECT substr('abcde', 1, 3);

BEGIN TRANSACTION;
ROLLBACK;


SELECT case
           when "rowNo" = 1 then concat(email, '@sizzler.co.th')
           else concat(concat(email, "rowNo", '@sizzler.co.th')) end,
       "employeeId"
FROM (
         SELECT concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3)) "email",
                row_number() over (partition by concat(replace(lower("firstname"), ' ', '_'), '.',
                                                       substr(lower("surname"), 1, 3)))            "rowNo",
                "employeeId"

         FROM "Employee"
     ) X;


SELECT DISTINCT concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3), '@sizzler.co.th'),
                count(*)
FROM "Employee"
group by concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3), '@sizzler.co.th');


-- Update EMPLOYEE data such as email, educationLevelId, provinceId
UPDATE "Employee" A
SET "email"            = (
    SELECT case
               when "rowNo" = 1 then concat(email, '@sizzler.co.th')
               else concat(concat(email, "rowNo", '@sizzler.co.th')) end
    FROM (
             SELECT concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3)) "email",
                    row_number() over (partition by concat(replace(lower("firstname"), ' ', '_'), '.',
                                                           substr(lower("surname"), 1, 3)))            "rowNo",
                    "employeeId"

             FROM "Employee"
            WHERE concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3)) = concat(replace(lower(A."firstname"), ' ', '_'), '.', substr(lower(A."surname"), 1, 3))
         ) X
    WHERE A."employeeId" = X."employeeId"
),
    "educationLevelId" = (
        SELECT "educationLevelId"
        FROM "EducationLevelRef"
        WHERE A."employeeId" = A."employeeId"
        ORDER BY (SELECT (SELECT random() WHERE g = g AND "educationLevelId" = "educationLevelId")
                  FROM generate_series(1, 10) g
                  limit 1)
        LIMIT 1
    ),
    "provinceId"       = (
        SELECT "Province"."provinceId"
        FROM "Province"
        WHERE A."employeeId" = A."employeeId"
        ORDER BY (SELECT (SELECT random() WHERE g = g AND "provinceId" = "provinceId")
                  FROM generate_series(1, 10) g
                  limit 1)
        LIMIT 1
    )
