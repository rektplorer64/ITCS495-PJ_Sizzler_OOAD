-- Generate Inventory Inbound Order transaction
DO
$$
    DECLARE
        "itBranch"           "Branch";
        "itBranchEstDate"    DATE;
        "itKitchenManagerId" UUID;
        "itOrderCount"       INT;
        "itIio"              "InventoryInboundOrder";
        "itIngredient"       "FoodIngredientRef";
        "isCanceled"         "bool";
        "unit"               INT;
        "itTimestamp"        "timestamp";
    BEGIN

        FOR "itBranch" IN (SELECT * FROM "Branch")
            LOOP
                SELECT "employeeId"
                INTO "itKitchenManagerId"
                FROM "EmployeeView"
                WHERE "workAtBranch" = "itBranch"."branchId"
                  AND 'Kitchen Manager' = ANY ("position")
                ORDER BY random()
                LIMIT 1;

                SELECT "establishingDate"
                INTO "itBranchEstDate"
                FROM "Branch"
                WHERE "branchId" = "itBranch"."branchId";

                "itTimestamp" := "itBranchEstDate";
                FOR "itOrderCount" IN 30.."random_between"(50, 200)
                    LOOP
                        "isCanceled" := random() < 0.1;
                        INSERT INTO "InventoryInboundOrder"
                        VALUES (DEFAULT,
                                "itTimestamp",
                                CASE
                                    WHEN "isCanceled"
                                        THEN ("itTimestamp" + ("random_between"(5, 30) || ' min')::INTERVAL) END,
                                'noot noot',
                                ("random_between"(23, 540) || ' min')::INTERVAL,
                                "itKitchenManagerId",
                                "itBranch"."branchId")
                        RETURNING * INTO "itIio";

                        FOR "itIngredient" IN (SELECT * FROM "FoodIngredientRef")
                            LOOP
                                CASE "itIngredient"."category"
                                    WHEN 'meat' THEN "unit" := 2;
                                    WHEN 'vegetable' THEN "unit" := 1;
                                    WHEN 'spice' THEN "unit" := 1;
                                    WHEN 'sauce' THEN "unit" := 3;
                                    WHEN 'desert' THEN "unit" := 2;
                                    WHEN 'beverage' THEN "unit" := 3;
                                    WHEN 'fruit' THEN "unit" := 2;
                                    ELSE "unit" := 8; END CASE;

                                INSERT INTO "InventoryInboundOrderItem"
                                VALUES (DEFAULT,
                                        CASE
                                            WHEN NOT "isCanceled" THEN "itIio"."timeCreated" +
                                                                       "itIio"."deliveryIn" +
                                                                       ("random_between"(20, 45) || ' min')::INTERVAL END,
                                        "itIio"."inboundOrderId",
                                        "itIngredient"."foodIngredientRefId",
                                        "random_between"(1, 30),
                                        "unit",
                                        "random_between"(45, 400));
                            END LOOP;
                        "itTimestamp" := "itTimestamp" + ('1 week ' || "random_between"(20, 450) || ' min')::INTERVAL;
                    END LOOP;

            END LOOP;
    END;
$$;

-- Generates SaladBarServing and SaladBarRefill
DO
$$
    DECLARE
        "itSaladBar"      "SaladBar";
        "i"               INT;
        "itFoodItemRefId" INT;
        "itServing"       "SaladBarServing";
        "branch"          "Branch";
        "itTimestamp"     TIMESTAMP;
    BEGIN

        FOR "itSaladBar" IN (SELECT * FROM "SaladBar")
            LOOP

                SELECT * INTO "branch" FROM "Branch" WHERE "branchId" = "itSaladBar"."branchId";

                FOR "itFoodItemRefId" IN (SELECT DISTINCT "foodItemRefId" FROM "SaladBarServing")
                    LOOP
                        SELECT *
                        INTO "itServing"
                        FROM "SaladBarServing"
                        WHERE "foodItemRefId" = "itFoodItemRefId"
                        LIMIT 1;
                        INSERT INTO "SaladBarServing"
                        VALUES ("itSaladBar"."saladBarId", "itFoodItemRefId",
                                "itServing"."maxQuantity" + "random_between"(45, 100), "itServing"."maxQuantityUnit")
                        ON CONFLICT DO NOTHING;
                    END LOOP;

                "itTimestamp" := ("branch"."establishingDate")::timestamp;
                -- raise NOTICE '%', "itTimestamp";
                FOR "i" IN 1.."random_between"(4000, 6000)
                    LOOP
                        SELECT *
                        INTO "itServing"
                        FROM "SaladBarServing"
                        WHERE "saladBarId" = "itSaladBar"."saladBarId"
                        ORDER BY random()
                        LIMIT 1;

                        INSERT INTO "SaladBarRefill"
                        VALUES ((SELECT "employeeId"
                                 FROM "EmployeeView"
                                 WHERE "workAtBranch" = "itSaladBar"."branchId"
                                   AND 'Chef' != ANY ("position")
                                   AND 'Branch Manager' != ANY ("position")
                                   AND 'Delivery Man' != ANY ("position")
                                 ORDER BY random()
                                 LIMIT 1),
                                "itSaladBar"."saladBarId",
                                "itServing"."foodItemRefId",
                                abs("itServing"."maxQuantity" - "random_between"(1, ("itServing"."maxQuantity" - 1)::INT)),
                                "itServing"."maxQuantityUnit", "itTimestamp");

                        "itTimestamp" := "itTimestamp" + ("random_between"(3200, 5600) || ' sec')::INTERVAL;
                    END LOOP;
            END LOOP;
    END;
$$