-- Fill Employee role information
DO
$$
    DECLARE
        "positions"        TEXT[] = '{cashier, chef, branch manager, delivery man, kitchen porter, kitchen manager}'::TEXT[];
        "itEmployee"       "Employee";
        "innerIterator"    INT;
        "prob"             "bool";
        "isManager"        "bool";
        "isKitchenManager" "bool";
    BEGIN
        RAISE NOTICE '%', "positions"[5];

        FOR "itEmployee" IN (SELECT * FROM "Employee")
            LOOP
                IF NOT exists(SELECT *
                              FROM "EmployeeView"
                              WHERE "workAtBranch" = "itEmployee"."branchId"
                                AND 'Branch Manager' = ANY ("position")
                                AND "age" >= 20) THEN
                    INSERT INTO "BranchManager" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;
                    CONTINUE;
                ELSIF NOT exists(SELECT *
                                 FROM "EmployeeView"
                                 WHERE "workAtBranch" = "itEmployee"."branchId"
                                   AND 'Kitchen Manager' = ANY ("position")
                                   AND "age" >= 20) THEN
                    INSERT INTO "KitchenManager" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;
                    CONTINUE;
                END IF;

                "isManager" = EXISTS(SELECT * FROM "BranchManager" WHERE "itEmployee"."employeeId" = "employeeId");

                IF (SELECT count(*)
                    FROM "EmployeeView"
                    WHERE "workAtBranch" = "itEmployee"."branchId"
                      AND 'Cashier' = ANY ("position")) < 4 THEN
                    INSERT INTO "Cashier" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;
                ELSIF (SELECT count(*)
                       FROM "EmployeeView"
                       WHERE "workAtBranch" = "itEmployee"."branchId"
                         AND 'Waiter' = ANY ("position")) < 10 THEN
                    INSERT INTO "Waiter" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;

                    INSERT INTO "WaiterLanguageFluency"
                        ((SELECT "itEmployee"."employeeId", "WorldLanguageRef"."worldLanguageRefId"
                          FROM "WorldLanguageRef"
                          WHERE "name" != 'Thai'
                          ORDER BY random()
                          LIMIT "random_between"(2, 3))
                         UNION
                         SELECT "itEmployee"."employeeId", "WorldLanguageRef"."worldLanguageRefId"
                         FROM "WorldLanguageRef"
                         WHERE "name" = 'Thai')
                    ON CONFLICT DO NOTHING;
                ELSIF (SELECT count(*)
                       FROM "EmployeeView"
                       WHERE "workAtBranch" = "itEmployee"."branchId"
                         AND 'Delivery Man' = ANY ("position")
                         AND NOT "isManager"
                         AND "age" > 18) < 3 THEN
                    INSERT INTO "DeliveryMan" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;
                ELSIF (SELECT count(*)
                       FROM "EmployeeView"
                       WHERE "workAtBranch" = "itEmployee"."branchId"
                         AND 'Chef' = ANY ("position")
                         AND NOT "isManager") < 10 THEN
                    INSERT INTO "Chef" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;
                    FOR "innerIterator" IN 1..3
                        LOOP
                            "prob" := random() < 0.4;
                            INSERT INTO "ChefCookingRole"
                            VALUES ("itEmployee"."employeeId", (SELECT "CookingRoleRef"."cookingRoleRefId"
                                                                FROM "CookingRoleRef"
                                                                ORDER BY random()
                                                                LIMIT 1),
                                    (CASE WHEN "prob" THEN 'high' ELSE 'medium' END)::"priority")
                            ON CONFLICT DO NOTHING;
                        END LOOP;
                ELSE
                    INSERT INTO "Waiter" VALUES ("itEmployee"."employeeId") ON CONFLICT DO NOTHING;

                    INSERT INTO "WaiterLanguageFluency"
                        ((SELECT "itEmployee"."employeeId", "WorldLanguageRef"."worldLanguageRefId"
                          FROM "WorldLanguageRef"
                          WHERE "name" != 'Thai'
                          ORDER BY random()
                          LIMIT "random_between"(2, 3))
                         UNION
                         SELECT "itEmployee"."employeeId", "WorldLanguageRef"."worldLanguageRefId"
                         FROM "WorldLanguageRef"
                         WHERE "name" = 'Thai');
                END IF;
            END LOOP;
    END
$$;


-- Generate Tables for each branch
DO
$$
    DECLARE
        "branch"   "Branch";
        "tableNum" INT;
    BEGIN
        FOR "branch" IN (SELECT * FROM "Branch")
            LOOP
                FOR "tableNum" IN 1.."random_between"(20, 40)
                    LOOP
                        INSERT INTO "Table" VALUES ("branch"."branchId", "tableNum") ON CONFLICT DO NOTHING;
                    END LOOP;
            END LOOP;
    END;
$$;


-- Select Billing that don't belong to any type.
SELECT "Billing"."billingId"
FROM "Billing"
         LEFT JOIN "BillingDelivery" "BD" ON "Billing"."billingId" = "BD"."billingId"
         LEFT JOIN "BillingOnSite" "BOS" ON "Billing"."billingId" = "BOS"."billingId"
WHERE "BD"."billingId" IS NULL
  AND "BOS"."billingId" IS NULL;

BEGIN TRANSACTION;
ROLLBACK;
COMMIT;

-- Fill Billing information by its category.
DO
$$
    DECLARE
        "incompleteBillingIds" UUID[];
        "itBillingId"          UUID;
        "randomResultBool"     BOOL;
        "countDelivery"        INT;
        "countOnSite"          INT;
        "tempBranch"           "Branch";
        "randomEmployeeId"     UUID;
        "itTableId"            INT;
        "itCashierMachineId"   UUID;
        "branchOpenTime"       TIME;
        "timeDur"              INTERVAL;
    BEGIN

        -- Select billing instances that don't classified into any type.
        SELECT array_agg("Billing"."billingId")
        INTO "incompleteBillingIds"
        FROM "Billing"
                 LEFT JOIN "BillingDelivery" "BD" ON "Billing"."billingId" = "BD"."billingId"
                 LEFT JOIN "BillingOnSite" "BOS" ON "Billing"."billingId" = "BOS"."billingId"
        WHERE "BD"."billingId" IS NULL
          AND "BOS"."billingId" IS NULL;

        RAISE NOTICE 'Array of ID that is not either delivery or on-site billing => %', "incompleteBillingIds";

        "countDelivery" := 0;
        "countOnSite" := 0;
        -- For each Billing that is not classified
        FOR "itBillingId" IN (
            SELECT "Billing"."billingId"
            FROM "Billing"
                     LEFT JOIN "BillingDelivery" "BD" ON "Billing"."billingId" = "BD"."billingId"
                     LEFT JOIN "BillingOnSite" "BOS" ON "Billing"."billingId" = "BOS"."billingId"
            WHERE "BD"."billingId" IS NULL
              AND "BOS"."billingId" IS NULL
        )
            LOOP
                RAISE NOTICE 'Iter Billing ID %', "itBillingId";
                "randomResultBool" := random() < 0.13;
                RAISE NOTICE 'NOTICE %', "randomResultBool";

                -- Select a random branch
                SELECT *
                INTO "tempBranch"
                FROM "Branch"
                ORDER BY random()
                LIMIT 1;

                -- Select Employee ID
                IF "randomResultBool" THEN
                    SELECT "employeeId"
                    INTO "randomEmployeeId"
                    FROM "EmployeeView"
                    WHERE 'Delivery Man' = ANY ("position")
                      AND "workAtBranch" = "tempBranch"."branchId";
                ELSE
                    SELECT "employeeId"
                    INTO "randomEmployeeId"
                    FROM "EmployeeView"
                    WHERE 'Cashier' = ANY ("position")
                      AND "workAtBranch" = "tempBranch"."branchId";
                END IF;

                --                 SELECT *
--                 INTO "tempBranch"
--                 FROM "Billing" "B"
--                          JOIN "CashierBillingHandling" "CBH" ON "B"."billingId" = "CBH"."billingId"
--                          JOIN "CashierMachine" "CM" ON "CBH"."cashierMachineId" = "CM"."computerMachineId"
--                          JOIN "ComputerMachine" "CM2" ON "CM"."computerMachineId" = "CM2"."computerMachineId"
--                 WHERE "B"."billingId" = "itBillingId";

                RAISE NOTICE 'branch => %', "tempBranch"."branchId";

                SELECT "timeOpening"
                INTO "branchOpenTime"
                FROM "Branch"
                         JOIN "BranchOpenTime" "BOT" ON "Branch"."branchId" = "BOT"."branchId";

                IF "randomResultBool" THEN
                    "countDelivery" = "countDelivery" + 1;

                    INSERT INTO "BillingDelivery"
                    VALUES ("itBillingId", "randomEmployeeId", ("random_between"(10, 45) || ' min')::"interval",
                            (random() * 20 + 1)::numeric(10,4))
                    ON CONFLICT DO NOTHING;

                    RAISE NOTICE 'date %', "tempBranch"."establishingDate";
                    INSERT INTO "CustomerDelivery"
                    VALUES (DEFAULT, "tempBranch"."establishingDate" +
                                     ("random_between"(0, least((EXTRACT(YEAR FROM "tempBranch"."establishingDate") + 15)::int, (EXTRACT(YEAR FROM now()))::int)) || ' years ' || "random_between"(1, 365) || ' days ' ||
                                      "random_between"(1, 129600) || ' seconds')::INTERVAL,
                            LPAD("random_between"(130, 13430430)::TEXT, 13, '0'), 'a', "tempBranch"."provinceId",
                            "itBillingId",
                            "tempBranch"."branchId")
                    ON CONFLICT DO NOTHING;
                ELSE
                    "countOnSite" = "countOnSite" + 1;
                    INSERT INTO "BillingOnSite" VALUES ("itBillingId");

                    SELECT "tableId"
                    INTO "itTableId"
                    FROM "Table"
                    WHERE "branchId" = "tempBranch"."branchId"
                    ORDER BY random()
                    LIMIT 1;

                    INSERT INTO "CustomerPax"
                    VALUES (DEFAULT, "tempBranch"."establishingDate" +
                                     ("random_between"(0, least((EXTRACT(YEAR FROM "tempBranch"."establishingDate") + 15)::int, (EXTRACT(YEAR FROM now()))::int)) || ' years ' || "random_between"(1, 365) || ' days ' ||
                                      "random_between"(1, 129600) || ' seconds')::INTERVAL, random_between(1, 10), "itTableId", "tempBranch"."branchId",
                            "itBillingId")
                    ON CONFLICT DO NOTHING;

                    SELECT "CM4"."computerMachineId"
                    INTO "itCashierMachineId"
                    FROM "Branch"
                             JOIN "ComputerMachine" "CM3" ON "Branch"."branchId" = "CM3"."branchId"
                             JOIN "CashierMachine" "CM4" ON "CM3"."computerMachineId" = "CM4"."computerMachineId"
                    WHERE "CM3"."branchId" = "tempBranch"."branchId"
                    ORDER BY random()
                    LIMIT 1;

                    INSERT INTO "CashierBillingHandling"
                    VALUES ("randomEmployeeId", "itCashierMachineId", "itBillingId")
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;

        RAISE NOTICE 'Count Delivery => % AND OnSite => %', "countDelivery", "countOnSite";

    END ;
$$;

BEGIN TRANSACTION;
ROLLBACK;
SELECT ("date"(now()) + ('23:12'::INTERVAL + ("random_between"(34, 467) || ' min')::INTERVAL))::TIMESTAMP;
SELECT least((EXTRACT(YEAR FROM now()))::int, 2);
-- Generate CustomerDelivery and CustomerPax