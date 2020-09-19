-- 3: List all customers with the level of membership, point gained, as well as the amount of money he/she spent.
SELECT "A"."memberCustomerId",
       "firstname",
       "surname",
       "telephoneNo",
       "email",
       sum("pointGained") "totalPointGained",
       sum("price")       "moneySpent",
       avg("orderCount")  "averageOrderPerBill"
FROM (
         SELECT "memberCustomerId",
                "firstname",
                "surname",
                "telephoneNo",
                "email",
                sum("pointReceived") "pointGained",
                "billingId"
         FROM "MemberCustomer" "MC"
                  JOIN "Billing" "B" ON "MC"."memberCustomerId" = "B"."involvedMemberCustomerId"
         GROUP BY "memberCustomerId", "billingId"
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
GROUP BY "A"."memberCustomerId", "firstname", "surname", "telephoneNo", "email";

-- 5: Summarize each employee's the total amount of working time as well as the wage payments
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
           AND ("clockOutTimestamp" >= (now() - '1 month'::INTERVAL)::DATE)
         GROUP BY "EV"."employeeId", "firstname", "surname", "nickname", "phoneNumbers", "birthdate", "age", "email"
     ) "A"

         LEFT JOIN "EmployeeWagePayment" "EWP" ON "A"."employeeId" = "EWP"."employeeId"
GROUP BY "A"."employeeId", "firstname", "surname", "nickname", "email", "phoneNumbers", "totalWorkTimeInThePastMonth",
         "birthdate",
         "age";

-- 17: Show work time of every employee
SELECT "EV"."employeeId",
       "firstname",
       "surname",
       "age",
       "workAtBranch",
       array_agg(ROW ("WT"."timeStart", "WT"."timeEnd", "dayOfWeek", ("timeEnd" - "timeStart"))) "workTime"
FROM "EmployeeView" "EV"
         JOIN "WorkTime" "WT" ON "EV"."employeeId" = "WT"."employeeId"
GROUP BY "EV"."employeeId", "firstname", "surname", "age", "workAtBranch";

-- 11: List the delivery time and distance take to finish each delivery
SELECT "DM".*, "BD"."timeUsed", "BD"."distanceKM"
FROM (
         SELECT "E"."employeeId" AS "deliveryManId", "firstname" "deliveryManFirstName", "surname" "deliveryManSurname"
         FROM "DeliveryMan" "DM"
                  JOIN "Employee" "E" ON "DM"."employeeId" = "E"."employeeId"
     ) "DM"
         JOIN "BillingDelivery" "BD" ON "DM"."deliveryManId" = "BD"."deliveryManId";

-- 30: List the details of each billing in details in terms of its type, timestamp and other related information.
CREATE OR REPLACE VIEW "BillingView" AS
SELECT "00".*,
       CASE
           WHEN "AA"."billingId" IS NOT NULL THEN 'delivery'
           WHEN "BB"."billingId" IS NOT NULL THEN 'on-site' END             "type",
       CASE
           WHEN "AA"."billingId" IS NOT NULL THEN ROW ("deliveryManId", "AA"."firstname", "AA"."surname")
           WHEN "BB"."billingId" IS NOT NULL
               THEN ROW ("cashierId", "BB"."firstname", "BB"."surname") END "handlerEmployee"
FROM (
         SELECT "billingId",
                "taxInvoiceId",
                "timeCreated",
                COALESCE("timePaid", "timeCanceled")                    "timeStatusModified",
                CASE
                    WHEN "timePaid" IS NOT NULL THEN 'paid'
                    WHEN "timeCanceled" IS NOT NULL THEN 'canceled' END "status",
                CASE
                    WHEN "involvedMemberCustomerId" IS NOT NULL THEN ROW ("involvedMemberCustomerId",
                        "pointReceived",
                        "pointExpirationTime") END                      "membershipBillCoupling"
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

-- 31: List all payment transaction that are ever made by any customer in any billing.
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


