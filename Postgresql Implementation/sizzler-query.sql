-- 6: Show date start and date end of all seasonal menu --
SELECT * FROM "SeasonRef"
-- 9: Show all of "western" serving menu --
SELECT "servingRefId", "nameEng", "nameTha", "basePrice" FROM "ServingRef" WHERE genre = 'western'
-- 12: Show the amount of table in each branch --
SELECT TB."branchId", name, COUNT("tableId") FROM "Table" TB INNER JOIN "Branch" B on B."branchId" = TB."branchId"
-- 15: Identify a menu that is the best seller in this month
SELECT "nameEng",COUNT("OrderItem"."menuRefId") FROM "OrderItem" INNER JOIN "MenuRef" MR on MR."menuRefId" = "OrderItem"."menuRefId"
GROUP BY "nameEng"
-- 16: Identify a member customer who spend most in this month --
SELECT "memberCustomerId", fullname,MAX(OverallPrice) AS "MaxSpendPrice"
FROM
    (
        SELECT "memberCustomerId", concat("firstname",' ', "surname") AS "fullname", SUM("price") AS OverallPrice
        FROM "MemberCustomer"
                 INNER JOIN "Billing" B on "MemberCustomer"."memberCustomerId" = B."involvedMemberCustomerId"
                 INNER JOIN "Order" O on B."billingId" = O."billingId"
                 INNER JOIN "OrderItem" OI on O."orderId" = OI."orderId"
        GROUP BY "memberCustomerId",fullname
    ) AS MemberSpendingSummary
GROUP BY "memberCustomerId",fullname
-- 19: Identify rewards customer redeem it recently --
SELECT concat("firstname",' ', "surname") AS "fullname", name FROM "MemberCustomer" INNER JOIN "MembershipRewardRedemption" MRR on "MemberCustomer"."memberCustomerId" = MRR."memberCustomerRefId" INNER JOIN "RedeemableRewardRef" RRR on RRR."redeemableRewardRefId" = MRR."redeemableRewardRefId"
WHERE "memberCustomerId" = 'b7a57961-b4ae-46f3-bf63-e20960e9a16b' ORDER BY "timestamp" DESC LIMIT 1
GROUP BY TB."branchId", name
-- 20: Identify member customer who order food within 7 days --
SELECT "memberCustomerId", concat("firstname",' ', "surname") AS "fullname" FROM "MemberCustomer" INNER JOIN "Billing" B on "MemberCustomer"."memberCustomerId" = B."involvedMemberCustomerId"
WHERE B."timePaid"> now() - interval '1 week'
-- 21: Show detail of order of each billing --
SELECT "Order"."orderId", "nameEng", "nameTha", "realPrice", "Order"."timeCreated" FROM "Order" INNER JOIN "Billing" B on B."billingId" = "Order"."billingId" INNER JOIN "OrderItem" OI on "Order"."orderId" = OI."orderId" INNER JOIN "MenuRef" MR on MR."menuRefId" = OI."menuRefId" INNER JOIN "MenuServingRef" MSR on MR."menuRefId" = MSR."menuRefId"