-- A1 <35>: Count all member customers that are grouped by each membership level.
SELECT "MLR"."name", COUNT("memberCustomerId") "numberOfMembers"
FROM "MemberCustomer" "MC"
         JOIN "MembershipRewardRedemption" "MRR"
              ON "MC"."memberCustomerId" = "MRR"."memberCustomerRefId"
         JOIN "MemberLevelRewardOffering" "MLRO" ON "MLRO"."redeemableRewardRefId" =
                                                    "MRR"."redeemableRewardRefId"
         JOIN "MemberLevelRef" "MLR" ON "MLRO"."memberLevelRefId" = "MLR"."memberLevelRefId"
GROUP BY "MLR"."name";

-- A2 <0.4>: Given a menu, identify one or more servings that are included as well as the price of each serving and the percentage it made up to the menu price.
SELECT "MR"."menuRefId",
       "MR"."nameEng"                                      "menuName",
       "MXR"."menuPrice",
       "MSR"."servingRefId",
       "SR"."nameEng"                                      "servingName",
       "realPrice"                                         "servingPrice",
       (("realPrice" / "menuPrice") * 100)::DECIMAL(16, 2) "servingPricePercentage"
FROM "MenuRef" "MR"
         JOIN "MenuServingRef" "MSR" ON "MR"."menuRefId" = "MSR"."menuRefId"
         JOIN "ServingRef" "SR" ON "MSR"."servingRefId" = "SR"."servingRefId"
         JOIN (SELECT "MenuRef"."menuRefId", sum("realPrice") "menuPrice"
               FROM "MenuRef"
                        JOIN "MenuServingRef" ON "MenuRef"."menuRefId" = "MenuServingRef"."menuRefId"
               GROUP BY "MenuRef"."menuRefId") "MXR" ON "MR"."menuRefId" = "MXR"."menuRefId"
ORDER BY "menuRefId";

-- A3 <20>: Identify member customers who have ordered foods within 7 days.
SELECT "memberCustomerId", concat("firstname", ' ', "surname") AS "fullname"
FROM "MemberCustomer"
         INNER JOIN "Billing" "B" ON "MemberCustomer"."memberCustomerId" = "B"."involvedMemberCustomerId"
WHERE "B"."timePaid" > now() - INTERVAL '1 week';

-- A4 <19>: Identify redeemable rewards that a customer recently redeem.
SELECT concat("firstname", ' ', "surname") AS "fullname", "name"
FROM "MemberCustomer"
         INNER JOIN "MembershipRewardRedemption" "MRR"
                    ON "MemberCustomer"."memberCustomerId" = "MRR"."memberCustomerRefId"
         INNER JOIN "RedeemableRewardRef" "RRR" ON "RRR"."redeemableRewardRefId" = "MRR"."redeemableRewardRefId"
WHERE "memberCustomerId" = 'b7a57961-b4ae-46f3-bf63-e20960e9a16b'
ORDER BY "timestamp" DESC
LIMIT 1;

-- A5 <34>: Identify the age that has the highest number of employees
SELECT "age", COUNT("employeeId") "numberOfEmployees"
FROM "Employee"
GROUP BY "age"
ORDER BY COUNT("employeeId") DESC
LIMIT 1;

-- A6 <0.5>: Identify the amount of each food item that needed to be refilled for the salad bar.
SELECT "branchId", "SB"."saladBarId", "nameEng", "maxQuantity" || ' ' || "name" || 's' "maxQuantity", "descriptionTha"
FROM "SaladBar" "SB"
         JOIN "SaladBarServing" "SBS" ON "SB"."saladBarId" = "SBS"."saladBarId"
         JOIN "FoodItemRef" "FIR" ON "SBS"."foodItemRefId" = "FIR"."foodItemRefId"
         JOIN "QuantityUnitRef" "QUR" ON "SBS"."maxQuantityUnit" = "QUR"."quantityUnitRefId";

-- A7 <1>: Identify the cash transaction that has the highest amount.
SELECT "PT".*, "CT"."amount"
FROM "PaymentTransaction" "PT"
         JOIN "CashTransaction" "CT" ON "PT"."paymentTransactionId" = "CT"."paymentTransactionId"
ORDER BY "amount" DESC
LIMIT 1;

-- A8 <12>: Identify the number of available tables in each branch.
SELECT "TB"."branchId", "name", COUNT("tableId") AS "tableAmount"
FROM "Table" "TB"
         INNER JOIN "Branch" "B" ON "B"."branchId" = "TB"."branchId"
GROUP BY "TB"."branchId", "name";

-- A9 <31>: Identify the top-10 credit transactions that have the highest amount.
SELECT "CT"."paymentTransactionId", "amount", "taxInvoiceId", "timeCreated", "status", "pointReceived"
FROM "CreditTransaction" "CT"
         JOIN "PaymentTransaction" "PT" ON "CT"."paymentTransactionId" = "PT"."paymentTransactionId"
         JOIN "BillingView" "BV" ON "BV"."billingId" = "PT"."billingId"
ORDER BY "amount" DESC
LIMIT 10;

-- A10 <15>: Identify the top-3 best seller menu in this month.
SELECT "nameEng", COUNT("OrderItem"."menuRefId") AS "saleAmount"
FROM "OrderItem"
         INNER JOIN "MenuRef" "MR" ON "MR"."menuRefId" = "OrderItem"."menuRefId"
WHERE "timeStarted" > now() - INTERVAL '1 month - 1 day'
GROUP BY "nameEng"
ORDER BY "saleAmount" DESC
LIMIT 3;

-- A11 <16>: Identify the top-3 member customers who spend the most.
SELECT "memberCustomerId", concat("firstname", ' ', "surname") AS "fullname", SUM("price") AS "overallPrice"
FROM "MemberCustomer"
         INNER JOIN "Billing" "B" ON "MemberCustomer"."memberCustomerId" = "B"."involvedMemberCustomerId"
         INNER JOIN "Order" "O" ON "B"."billingId" = "O"."billingId"
         INNER JOIN "OrderItem" "OI" ON "O"."orderId" = "OI"."orderId"
GROUP BY "memberCustomerId", "fullname"
ORDER BY "overallPrice" DESC
LIMIT 3;

-- A12 <37>: Identify the total sale frequency of each menu.
SELECT "MR"."menuRefId", "nameEng", COUNT("quantity") "sellCount"
FROM "MenuRef" "MR"
         JOIN "OrderItem" "OI" ON "MR"."menuRefId" = "OI"."menuRefId"
GROUP BY "MR"."menuRefId", "nameEng"
ORDER BY COUNT("quantity") DESC;

-- A13 <0.1>: List all branches details in a given province of Thailand.
CREATE OR REPLACE VIEW "BranchView" AS
SELECT "B"."branchId",
       "name",
       "P"."nameThai"                                      "province",
       "totalEmployees",
       "totatAvailableTables",
       "fullAddress",
       ARRAY ["coordinateLatitude", "coordinateLongitude"] "coordinate",
       "email",
       "telephoneNoList",
       "establishingDate",
       "status"
FROM "Branch" "B"
         JOIN "Province" "P" ON "B"."provinceId" = "P"."provinceId"
         JOIN (
    SELECT "TAB"."branchId", "telephoneNoList", "totatAvailableTables"
    FROM (
             SELECT "branchId", array_agg("telephoneNo") "telephoneNoList" FROM "BranchTelephone" GROUP BY "branchId"
         ) "TEL"
             JOIN (
        SELECT "branchId", COUNT("tableId") "totatAvailableTables" FROM "Table" GROUP BY "branchId"
    ) "TAB" ON "TEL"."branchId" = "TAB"."branchId"
) "XYZ" ON "XYZ"."branchId" = "B"."branchId"
         JOIN (
    SELECT "branchId", count("employeeId") "totalEmployees"
    FROM "Employee" "E"
    GROUP BY "branchId"
) "EMP" ON "B"."branchId" = "EMP"."branchId";

-- A14 <3>: List all customers with the level of membership, point gained, as well as the amount of money he/she spent.
CREATE OR REPLACE VIEW "MemberCustomerView" AS
SELECT "A"."memberCustomerId",
       "firstname",
       "surname",
       "telephoneNo",
       "email",
       "membershipLevel",
       sum("pointGained") "totalPointGained",
       sum("price")       "totalSpending",
       avg("orderCount")  "averageOrdersPerBill"
FROM (
         SELECT "MC"."memberCustomerId",
                "firstname",
                "surname",
                "telephoneNo",
                "email",
                sum("pointReceived") "pointGained",
                sum("pointSpent")    "pointUsed",
                "billingId",
                "membershipLevel"
         FROM "MemberCustomer" "MC"
                  LEFT JOIN (SELECT "name" "membershipLevel",
                                    "A1"."memberCustomerId",
                                    rank() OVER (PARTITION BY "memberCustomerId" ORDER BY "timestamp" DESC)
                             FROM (
                                      SELECT "MLG"."memberCustomerId", "name", "timestamp"
                                      FROM "MemberLevelGrant" "MLG"
                                               JOIN "MemberLevelRef" "MLR"
                                                    ON "MLG"."memberLevelRefId" = "MLR"."memberLevelRefId"
                                  ) "A1") "X" ON "X"."memberCustomerId" = "MC"."memberCustomerId"
                  JOIN "Billing" "B" ON "MC"."memberCustomerId" = "B"."involvedMemberCustomerId"
                  JOIN "MembershipRewardRedemption" "MRR" ON "MC"."memberCustomerId" = "MRR"."memberCustomerRefId"
         GROUP BY "MC"."memberCustomerId", "billingId", "membershipLevel"
     ) "A"
         JOIN (
    SELECT "O"."billingId",
           "O"."orderId",
           sum("calculateOrderItemPrice"("perUnitPrice", "perUnitTakeHomeFee", "perUnitDiscount", "quantity")) "price",
           count("orderItemId")                                                                                "orderCount"
    FROM "Billing"
             JOIN "Order" "O" ON "Billing"."billingId" = "O"."billingId"
             JOIN "OrderItem" "O2" ON "O"."orderId" = "O2"."orderId"
    GROUP BY "O"."billingId", "O"."orderId"
) "B" ON "A"."billingId" = "B"."billingId"
GROUP BY "A"."memberCustomerId", "firstname", "surname", "telephoneNo", "email", "membershipLevel";

-- A15 <0.3>: List all Inventory Inbound Order details grouped by branch.
SELECT "IIO"."inboundOrderId",
       "IIO"."branchId",
       "IIO"."timeCreated",
       "IIO"."deliveryIn",
       "IIO"."note",
       "nameTha"                          "ingredientName",
       "quantity" || ' ' || "name" || 's' "amount",
       "quantity" * "pricePerUnit"        "totalPrice"
FROM "InventoryInboundOrder" "IIO"
         JOIN "InventoryInboundOrderItem" "IIOI" ON "IIO"."inboundOrderId" = "IIOI"."inboundOrderId"
         JOIN "FoodIngredientRef" "FIR" ON "FIR"."foodIngredientRefId" = "IIOI"."foodIngredientRefId"
         JOIN "QuantityUnitRef" "QUR" ON "IIOI"."quantityUnitRefId" = "QUR"."quantityUnitRefId";

-- A16 <32>: List all payment transactions that are ever made by any customer in any billing.
CREATE OR REPLACE VIEW "PaymentTransactionView" AS
SELECT "PT"."paymentTransactionId",
       "timestamp",
       "billingId",
       CASE
           WHEN "CT"."paymentTransactionId" IS NOT NULL THEN 'cash'
           WHEN "CT2"."paymentTransactionId" IS NOT NULL THEN 'credit'
           WHEN "GVT"."paymentTransactionId" IS NOT NULL THEN 'gift voucher' END                                      "type",
       CASE
           WHEN "CT"."paymentTransactionId" IS NOT NULL THEN "CT"."amount"
           WHEN "CT2"."paymentTransactionId" IS NOT NULL THEN "CT2"."amount"
           WHEN "GVT"."paymentTransactionId" IS NOT NULL THEN (SELECT "valueAmount"
                                                               FROM "GiftVoucherRef" "GVR"
                                                               WHERE "GVR"."valueAmount" = "GVT"."giftVoucherNo") END "value"
FROM "PaymentTransaction" "PT"
         LEFT JOIN "CashTransaction" "CT" ON "PT"."paymentTransactionId" = "CT"."paymentTransactionId"
         LEFT JOIN "CreditTransaction" "CT2" ON "PT"."paymentTransactionId" = "CT2"."paymentTransactionId"
         LEFT JOIN "GiftVoucherTransaction" "GVT" ON "PT"."paymentTransactionId" = "GVT"."paymentTransactionId";

-- A17 <30>: List the details of each billing in detail in terms of its type, timestamp, responsible employee, and other related information.
CREATE OR REPLACE VIEW "BillingView" AS
SELECT "00".*,
       CASE
           WHEN "AA"."billingId" IS NOT NULL THEN 'delivery'
           WHEN "BB"."billingId" IS NOT NULL THEN 'on-site' END "type",
       CASE
           WHEN "AA"."billingId" IS NOT NULL THEN "deliveryManId"
           WHEN "BB"."billingId" IS NOT NULL
               THEN "cashierId" END                             "handlerEmployeeId",
       CASE
           WHEN "AA"."billingId" IS NOT NULL THEN "AA"."firstname"
           WHEN "BB"."billingId" IS NOT NULL
               THEN "BB"."firstname" END                        "handlerEmployeeFirstname",
       CASE
           WHEN "AA"."billingId" IS NOT NULL THEN "AA"."surname"
           WHEN "BB"."billingId" IS NOT NULL
               THEN "BB"."surname" END                          "handlerEmployeeSurname"
FROM (
         SELECT "billingId",
                "taxInvoiceId",
                "timeCreated",
                COALESCE("timePaid", "timeCanceled")                    "timeStatusModified",
                CASE
                    WHEN "timePaid" IS NOT NULL THEN 'paid'
                    WHEN "timeCanceled" IS NOT NULL THEN 'canceled' END "status",
                "involvedMemberCustomerId",
                "pointReceived",
                "pointExpirationTime"
         FROM "Billing"
     ) "00"
         LEFT JOIN (
    SELECT "BD"."billingId", "deliveryManId", "EV"."firstname", "EV"."surname"
    FROM "BillingDelivery" "BD"
             JOIN "EmployeeView" "EV" ON "deliveryManId" = "employeeId"
) "AA" ON "00"."billingId" = "AA"."billingId"
         LEFT JOIN (
    SELECT "BS"."billingId", "cashierId", "EV"."firstname", "EV"."surname"
    FROM "BillingOnSite" "BS"
             JOIN "CashierBillingHandling" "CBH" ON "BS"."billingId" = "CBH"."billingId"
             JOIN "EmployeeView" "EV" ON "CBH"."cashierId" = "employeeId"
) "BB" ON "00"."billingId" = "BB"."billingId";

-- A18 <0.2>: List the details of each menu with respects to current availability.
SELECT "MR".*,
       "MenuAvailability"."menuRefId" IS NOT NULL "isAvailable",
       "MenuWitoutSeason"."menuRefId" IS NULL     "hasSeason",
       "MenuWithCurrentSeason" IS NOT NULL        "inSeason",
       "isActive" AND ("MenuAvailability"."menuRefId" IS NOT NULL) AND
       (CASE
            WHEN "MenuWitoutSeason"."menuRefId" IS NULL
                THEN ("MenuWithCurrentSeason" IS NOT NULL)
            ELSE TRUE END)                        "finallyNowAvailable?",
       "availableAtBranch"
FROM (SELECT * FROM "MenuRef" WHERE "isActive") "MR"
         LEFT JOIN
     (
         SELECT "menuRefId"
         FROM "MenuAvailability" "MA2"
         WHERE date_part('dow', now()) = "mapToDayOfWeekInt"("dayOfWeek")
           AND '10:00'::TIME BETWEEN "timeRangeStart" AND "timeRangeEnd") "MenuAvailability"
     ON "MR"."menuRefId" = "MenuAvailability"."menuRefId"
         LEFT JOIN (
    SELECT "menuRefId"
    FROM "MenuSeasonRef" "MSR"
             LEFT JOIN
         (SELECT *
          FROM "SeasonRef"
          WHERE now() BETWEEN "dateStart" AND "dateEnd") "SR" ON "MSR"."seasonRefId" = "SR"."seasonRefId"
) "MenuWithCurrentSeason" ON "MR"."menuRefId" = "MenuWithCurrentSeason"."menuRefId"
         LEFT JOIN (SELECT "MenuRef"."menuRefId"
                    FROM "MenuRef"
                             LEFT JOIN "MenuSeasonRef" "MSR2" ON "MenuRef"."menuRefId" = "MSR2"."menuRefId"
                    WHERE "MSR2"."menuRefId" IS NULL) "MenuWitoutSeason"
                   ON "MenuWitoutSeason"."menuRefId" = "MR"."menuRefId"
         LEFT JOIN (SELECT "menuRefId", array_agg("branchId") "availableAtBranch"
                    FROM "BranchMenuAvailability"
                    GROUP BY "menuRefId") "AvailableBranch" ON "AvailableBranch"."menuRefId" = "MR"."menuRefId";

-- A19 <21>: List the details of orders given a billing information.
SELECT "Order"."orderId", "nameEng", "nameTha", "realPrice", "Order"."timeCreated"
FROM "Order"
         INNER JOIN "Billing" "B" ON "B"."billingId" = "Order"."billingId"
         INNER JOIN "OrderItem" "OI" ON "Order"."orderId" = "OI"."orderId"
         INNER JOIN "MenuRef" "MR" ON "MR"."menuRefId" = "OI"."menuRefId"
         INNER JOIN "MenuServingRef" "MSR" ON "MR"."menuRefId" = "MSR"."menuRefId";

-- A20 <36>: Show customer first name, surname, and member level.
SELECT "MCV"."memberCustomerId", "MCV"."firstname", "MCV"."surname", "MCV"."membershipLevel"
FROM "MemberCustomerView" "MCV";

-- A21 <22>: Show food ingredients in each food item.
SELECT "FoodItemRef"."nameTha", "FoodIngredientRef"."nameTha", "quantity", "QuantityUnitRef"."name"
FROM "FoodItemRef"
         JOIN "FoodItemIngredientRef" ON "FoodItemRef"."foodItemRefId" = "FoodItemIngredientRef"."foodItemRefId"
         JOIN "FoodIngredientRef"
              ON "FoodItemIngredientRef"."foodIngredientRef" = "FoodIngredientRef"."foodIngredientRefId"
         JOIN "QuantityUnitRef" ON "FoodItemIngredientRef"."quantityUnitRefId" = "QuantityUnitRef"."quantityUnitRefId";

-- A22 <14>: Show the number of customers within a day.
SELECT "timeAdded"::DATE, SUM("totalCustomers") AS "TotalInDay"
FROM "CustomerPax"
WHERE "timeAdded" BETWEEN '2020-02-08 00:00:00' AND '2020-02-08 23:59:59'
GROUP BY "timeAdded"::DATE;

-- A23 <26>: Show the total distance in kilometers that a delivery man has ever delivered.
SELECT "BillingDelivery"."deliveryManId", SUM("distanceKM") AS "TotalDistance"
FROM "BillingDelivery"
         JOIN "DeliveryMan" ON "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
WHERE "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
GROUP BY "BillingDelivery"."deliveryManId";

-- A24 <5>: Summarize each employee's the total amount of working time as well as the wage payments.
SELECT "A"."employeeId",
       "firstname",
       "surname",
       "nickname",
       "birthdate",
       "age",
       "email",
       "phoneNumbers",
       "totalWorkTimeInThePastMonth",
       sum(coalesce("EWP"."wagePaymentAmount", 0)) "totalWagePaid",
       sum(coalesce("EWP"."wageBonusAmount", 0))   "totalBonusPaid"
FROM (
         SELECT "EV"."employeeId",
                "firstname",
                "surname",
                "nickname",
                "phoneNumbers",
                "birthdate",
                "age",
                "email",
                sum((coalesce("CICO"."clockOutTimestamp" - "CICO"."clockInTimestamp",
                              '0 min'))::INTERVAL) "totalWorkTimeInThePastMonth"
         FROM "EmployeeView" "EV"
                  LEFT JOIN "ClockInClockOut" "CICO"
                            ON "EV"."employeeId" = "CICO"."employeeId"
         WHERE ("clockInTimestamp" <= (now()::DATE))
           AND ("clockOutTimestamp" >= (now() - '10 month'::INTERVAL)::DATE)
         GROUP BY "EV"."employeeId", "firstname", "surname", "nickname", "phoneNumbers", "birthdate", "age", "email"
     ) "A"
         LEFT JOIN "EmployeeWagePayment" "EWP" ON "A"."employeeId" = "EWP"."employeeId"
GROUP BY "A"."employeeId", "firstname", "surname", "nickname", "email", "phoneNumbers", "totalWorkTimeInThePastMonth",
         "birthdate",
         "age";

-- A25 <11>: List the delivery time, distance and average speed take to finish each delivery.
SELECT "DM".*,
       "BD"."timeUsed",
       "BD"."distanceKM",
       "CD"."fullAddress",
       "CD"."handlingBranchId",
       ROUND(("distanceKM" / (EXTRACT(EPOCH FROM "timeUsed") / 3600))::NUMERIC, 4) "averageSpeed"
FROM (
         SELECT "E"."employeeId" AS "deliveryManId", "firstname" "deliveryManFirstName", "surname" "deliveryManSurname"
         FROM "DeliveryMan" "DM"
                  JOIN "Employee" "E" ON "DM"."employeeId" = "E"."employeeId"
     ) "DM"
         JOIN "BillingDelivery" "BD" ON "DM"."deliveryManId" = "BD"."deliveryManId"
         JOIN "CustomerDelivery" "CD" ON "BD"."billingId" = "CD"."deliveryBillingId";

