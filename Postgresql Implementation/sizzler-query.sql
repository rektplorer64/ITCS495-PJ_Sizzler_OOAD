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