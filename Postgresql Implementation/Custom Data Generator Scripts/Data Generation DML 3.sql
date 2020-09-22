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
        "itTimestamp"       "timestamp";
    BEGIN

        FOR "itBranch" IN (SELECT * FROM "Branch")
            LOOP
                SELECT "employeeId"
                INTO "itKitchenManagerId"
                FROM "EmployeeView"
                WHERE "workAtBranch" = "itBranch"."branchId" AND 'Kitchen Manager' = ANY("position")
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