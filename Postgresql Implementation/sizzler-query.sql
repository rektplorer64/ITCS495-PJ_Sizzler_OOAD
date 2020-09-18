-- List all customers with the level of membership, point gained, as well as the amount of money he/she spent.
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

SELECT "memberCustomerId",
       "firstname",
       "surname",
       "telephoneNo",
       "email",
       sum("pointReceived")                          "pointGained",
       coalesce("B2"."billingId", "BOS"."billingId") "billing"
FROM "MemberCustomer" "MC"
         JOIN "Billing" "B" ON "MC"."memberCustomerId" = "B"."involvedMemberCustomerId"
         LEFT JOIN "BillingDelivery" "B2" ON "B"."billingId" = "B2"."billingId"
         LEFT JOIN "BillingOnSite" "BOS" ON "B"."billingId" = "BOS"."billingId"
GROUP BY "memberCustomerId", "B2"."billingId", "BOS"."billingId";


SELECT "O"."billingId",
       "O"."orderId",
       sum("calculateOrderItemPrice"("perUnitPrice", "perUnitTakeHomeFee", "perUnitDiscount", "quantity")) "price",
       count("orderItemId")                                                                                "orderCount"
FROM "Billing"
         JOIN "Order" "O" ON "Billing"."billingId" = "O"."billingId"
         JOIN "OrderItem" "O2" ON "O"."orderId" = "O2"."orderId"
GROUP BY "O"."billingId", "O"."orderId";



SELECT "memberCustomerId", sum("pointReceived")
FROM "MemberCustomer" "MC"
         JOIN "Billing" "B" ON "MC"."memberCustomerId" = "B"."involvedMemberCustomerId"
GROUP BY "memberCustomerId";


SELECT "memberCustomerId", "firstname", "surname", "MC"."email", "telephoneNo", "name" AS "liveNearBranch"
FROM "MemberCustomer" "MC"
         JOIN "Branch" "B" ON "MC"."liveNearBranchId" = "B"."branchId";
