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
SET "pointExpirationTime" = '1 year'::interval,
"pointReceived" = floor(random()* (1000-100 + 1) + 100),
    "involvedMemberCustomerId" = (
        SELECT "memberCustomerId"
        FROM "MemberCustomer"
        WHERE A."billingId" = A."billingId"
        ORDER BY (SELECT (SELECT random() WHERE g = g AND A."billingId" = A."billingId")
                                       FROM generate_series(1, 10) g
                                       limit 1)
        LIMIT 1
        )
    WHERE "timePaid" IS NOT NULL AND random() < 0.2