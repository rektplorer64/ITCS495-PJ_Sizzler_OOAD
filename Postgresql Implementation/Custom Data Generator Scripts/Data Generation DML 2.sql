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
                            (random() * 20 + 1)::NUMERIC(10, 4))
                    ON CONFLICT DO NOTHING;

                    RAISE NOTICE 'date %', "tempBranch"."establishingDate";
                    INSERT INTO "CustomerDelivery"
                    VALUES (DEFAULT, "tempBranch"."establishingDate" +
                                     ("random_between"(0, least(
                                             (EXTRACT(YEAR FROM "tempBranch"."establishingDate") + 15)::INT,
                                             (EXTRACT(YEAR FROM now()))::INT)) || ' years ' ||
                                      "random_between"(1, 365) || ' days ' ||
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
                                     ("random_between"(0, least(
                                             (EXTRACT(YEAR FROM "tempBranch"."establishingDate") + 15)::INT,
                                             (EXTRACT(YEAR FROM now()))::INT)) || ' years ' ||
                                      "random_between"(1, 365) || ' days ' ||
                                      "random_between"(1, 129600) || ' seconds')::INTERVAL, "random_between"(1, 10),
                            "itTableId", "tempBranch"."branchId",
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


-- Order and OrderItems
DO
$$
    DECLARE
        "iterationCount"   INT := 0;
        "iterationCount2"  INT := 0;
        "orderTime"        TIMESTAMP;
        "billing"          "Billing";
        "isDelivery"       BOOL;
        "orderCount"       INT;
        "paxInstance"      INT;
        "deliveryInstance" INT;
        "branchId"         UUID;
        "waiter"           "EmployeeView";
        "itOrderId"        INT;
        "itTimeCreated"    TIMESTAMP;
        "itMenuRef"        "MenuRef";
        "itMenuPrice"      "numeric"(16, 2);
        "itTakeHome"       BOOL;
    BEGIN

        FOR "billing" IN (SELECT * FROM "Billing")
            LOOP

                "isDelivery" := EXISTS(SELECT * FROM "BillingDelivery" WHERE "billing"."billingId" = "billingId");

                IF "isDelivery" THEN
                    "orderCount" := 1;
                    SELECT "customerInstanceId"
                    INTO "deliveryInstance"
                    FROM "CustomerDelivery"
                    WHERE "deliveryBillingId" = "billing"."billingId";

                    SELECT "handlingBranchId"
                    INTO "branchId"
                    FROM "CustomerDelivery" "CD";

                    "paxInstance" := NULL;
                ELSE
                    SELECT "random_between"(1, 10) INTO "orderCount";
                    SELECT "customerInstanceId"
                    INTO "paxInstance"
                    FROM "CustomerPax"
                    WHERE "onSiteBillingId" = "billing"."billingId";

                    SELECT "tableBranchId"
                    INTO "branchId"
                    FROM "CustomerPax";
                    "deliveryInstance" := NULL;
                END IF;

                FOR "iterationCount" IN 1.."orderCount"
                    LOOP
                        SELECT *
                        INTO "waiter"
                        FROM "EmployeeView" "EV"
                        WHERE "branchId" = "EV"."workAtBranch"
                          AND 'Waiter' = ANY ("position");

                        INSERT INTO "Order"
                        VALUES (DEFAULT, "billing"."timeCreated", NULL, "paxInstance", "deliveryInstance",
                                "waiter"."employeeId", "billing"."billingId")
                        ON CONFLICT("orderId") DO UPDATE SET "orderId" = (SELECT max("orderId") + 1 FROM "Order")
                        RETURNING "orderId", "timeCreated" INTO "itOrderId", "itTimeCreated";

                        RAISE NOTICE 'orderId => %, timeCreate => %', "itOrderId", "itTimeCreated";
                        FOR "iterationCount2" IN 1.."random_between"(1, 5)
                            LOOP
                                "itTimeCreated" = "itTimeCreated" +
                                                  ("random_between"("iterationCount2" * 20, ("iterationCount2" + 1) * 20) ||
                                                   ' min')::INTERVAL;

                                SELECT * INTO "itMenuRef" FROM "MenuRef" ORDER BY random() LIMIT 1;

                                SELECT sum("realPrice")::NUMERIC(16, 2)
                                INTO "itMenuPrice"
                                FROM "MenuRef"
                                         JOIN "MenuServingRef" ON "MenuRef"."menuRefId" = "MenuServingRef"."menuRefId"
                                WHERE "MenuRef"."menuRefId" = "itMenuRef"."menuRefId";

                                "itTakeHome" = NOT "isDelivery" AND random() < 0.02;

                                INSERT INTO "OrderItem"
                                VALUES (DEFAULT,
                                        "itOrderId",
                                        "itMenuRef"."menuRefId",
                                        "random_between"(1, 3),
                                        "itTimeCreated",
                                        "itTimeCreated" + ("random_between"(4, 8) || ' min')::"interval",
                                        "itMenuPrice",
                                        "random_between"(50, 100),
                                        CASE WHEN "itTakeHome" THEN 50 END,
                                        DEFAULT) ON CONFLICT ("orderItemId") DO UPDATE SET "orderItemId" = (SELECT MAX("orderItemId") + 1 FROM "OrderItem");
                            END LOOP;
                    END LOOP;
            END LOOP;


    END;
$$;

-- Fill registration time by inferring from the birthday of each customer
DO
$$
    DECLARE
        "itMemberCustomer" "MemberCustomer";
    BEGIN
        FOR "itMemberCustomer" IN (SELECT * FROM "MemberCustomer")
            LOOP
                UPDATE "MemberCustomer"
                SET "registrationTimestamp" = "birthdate" + ("random_between"(14,
                                                                              (extract(YEAR FROM age(now(), "itMemberCustomer"."birthdate")) - 1)::int) ||
                                                             ' year ' || "random_between"(1, 12) || ' month ' ||
                                                             "random_between"(1, 30) || ' day ' ||
                                                             "random_between"(1, 24) || ' hour ' ||
                                                             "random_between"(1, 60) || ' second ')::"interval"
                WHERE "memberCustomerId" = "itMemberCustomer"."memberCustomerId";
            END LOOP;
    END;
$$;

-- Add linkage between MemberCustomer and MemberLevelRef
DO
$$
    DECLARE
        "itMember"            "MemberCustomer";
        "membershipCount"     INT := 1;
        "i"                   INT;
        "lastMembershipLevel" "MemberLevelRef";
        "lastMembershipTime"  "timestamp";
        "duration"              interval;
    BEGIN
        FOR "itMember" IN (SELECT * FROM "MemberCustomer")
            LOOP
                -- Grant everyone with a green level member
                INSERT INTO "MemberLevelGrant"
                VALUES ((SELECT "MemberLevelRef"."memberLevelRefId" FROM "MemberLevelRef" WHERE "name" = 'Green'),
                        "itMember"."memberCustomerId",
                        "itMember"."registrationTimestamp" + ("random_between"(1, 120000) || ' second')::INTERVAL)
                RETURNING "timestamp" INTO "lastMembershipTime";

                "membershipCount" := 0;
                FOR "i" IN 1.."random_between"(1, 20)
                    LOOP
                        "membershipCount" = "membershipCount" + 1;

                        IF "membershipCount" > 3 THEN
                            "membershipCount" = 3;
                        END IF;

                        IF "membershipCount" = 1 THEN
                            SELECT *
                            INTO "lastMembershipLevel"
                            FROM "MemberLevelRef"
                            WHERE "name" = 'Green';
                        ELSIF "membershipCount" = 2 THEN
                            SELECT *
                            INTO "lastMembershipLevel"
                            FROM "MemberLevelRef"
                            WHERE "name" = 'Gold';
                        ELSE
                            SELECT *
                            INTO "lastMembershipLevel"
                            FROM "MemberLevelRef"
                            WHERE "name" = 'Diamond';
                        END IF;

                        IF random() < 0.5 THEN
                            "membershipCount" = "membershipCount" - 1;
                            IF "membershipCount" < 1 OR "membershipCount" = 1 THEN
                                "membershipCount" = 1;

                                "duration" := '1 year'::interval + ("random_between"(1, 70) || ' week')::INTERVAL;
                            ELSE
                                "duration" := ("random_between"(1, 20) || ' week')::INTERVAL;
                            END IF;
                        ELSE
                            "duration" := ("random_between"(1, 10) || ' week')::INTERVAL;
                        END IF;

                        INSERT INTO "MemberLevelGrant"
                        VALUES ("lastMembershipLevel"."memberLevelRefId",
                                "itMember"."memberCustomerId",
                                ("lastMembershipTime" + "duration")::timestamp) RETURNING "timestamp" INTO "lastMembershipTime";
                    END LOOP;
            END LOOP;
    END;
$$;

-- Populate ClockInClockOut rows to with respects to available employee records.
DO
$$
    DECLARE
        "itEmployee" "Employee";
        "itWorkTime" "WorkTime";
        "attendanceMachineId" uuid;
        "itPreviousDate" date;
        "itDay" int;
        "maxDay" int;
        "itPreviousDow" "day_of_week";
        "itPreviousDowInt" int;
    BEGIN
        FOR "itEmployee" IN (SELECT * FROM "Employee")
            LOOP

                SELECT "TAM"."computerMachineId" INTO "attendanceMachineId"
                FROM "ComputerMachine" "CM" JOIN "TimeAttendanceMachine" "TAM" ON "CM"."computerMachineId" = "TAM"."computerMachineId"
                WHERE "branchId" = "itEmployee"."branchId"
                ORDER BY random()
                LIMIT 1;

                "itPreviousDate" := "itEmployee"."joinDate";

                SELECT (date_part('day', now() - "itPreviousDate") * 0.6)::int INTO "maxDay";
                raise notice 'day => %', "maxDay";
                FOR itDay IN 1..random_between(50, "maxDay")
                    LOOP
                        "itPreviousDowInt" := date_part('dow', "itPreviousDate");
                        CASE "itPreviousDowInt"
                            WHEN 0 THEN "itPreviousDow" := 'sunday';
                            WHEN 1 THEN "itPreviousDow" := 'monday';
                            WHEN 2 THEN "itPreviousDow" := 'tuesday';
                            WHEN 3 THEN "itPreviousDow" := 'wednesday';
                            WHEN 4 THEN "itPreviousDow" := 'thursday';
                            WHEN 5 THEN "itPreviousDow" := 'friday';
                            ELSE "itPreviousDow" := 'saturday'; END CASE;

                            SELECT * INTO "itWorkTime" FROM "WorkTime" WHERE "employeeId" = "itEmployee"."employeeId" AND "dayOfWeek" = "itPreviousDow";

                        INSERT INTO "ClockInClockOut"
                            VALUES ("attendanceMachineId",
                                    "itEmployee"."employeeId",
                                    (date("itPreviousDate") || ' ' || ("itWorkTime"."timeStart" - ('5 min')::interval)::time)::timestamp,
                                    (date("itPreviousDate") || ' ' || ("itWorkTime"."timeEnd" + ('5 min')::interval)::time)::timestamp,
                                    "itWorkTime"."workTimeId");

                        "itPreviousDate" := "itPreviousDate" + ('1 day')::interval;
                    END LOOP;
            END LOOP;
    END
$$;

-- Populate the data for the Menu Availability of each branch.
DO
$$
    DECLARE
        "itMenuRef" "MenuRef";
        "itBranch" "Branch";
    BEGIN
        FOR "itBranch" IN (SELECT * FROM "Branch")
            LOOP
                FOR "itMenuRef" IN (SELECT * FROM "MenuRef")
                    LOOP
                        IF random() < 0.1 THEN
                            CONTINUE;
                        END IF;
                        INSERT INTO "BranchMenuAvailability" VALUES ("itBranch"."branchId", "itMenuRef"."menuRefId");
                    END LOOP;
            END LOOP;
    END;
$$;