-- 6: Show date start and date end of all seasonal menu --
SELECT * FROM "SeasonRef"
-- 16: Identify a member customer who spend most in this month --
-- run ได้ แต่ไม่มีข้อมูล เพราะใน order ไม่มี order อันไหนเลยที่นสั่งเป็นคนที่มีบัตรสมาชิก --
SELECT "memberCustomerId",MAX(OverallPrice) AS "MaxSpendPrice"
FROM
    (
        SELECT "memberCustomerId", SUM("realPrice") AS OverallPrice
        FROM "MemberCustomer"
                 INNER JOIN "Billing" B on "MemberCustomer"."memberCustomerId" = B."involvedMemberCustomerId"
                 INNER JOIN "Order" O on B."billingId" = O."billingId"
                 INNER JOIN "OrderItem" OI on O."orderId" = OI."orderId"
                 INNER JOIN "MenuRef" MR on MR."menuRefId" = OI."menuRefId"
                 INNER JOIN "MenuServingRef" MSR on MR."menuRefId" = MSR."menuRefId"
        GROUP BY "memberCustomerId"
    ) AS MemberSpendingSummary
GROUP BY "memberCustomerId"