-- B1 <33>: Count employees group by age
SELECT "age", COUNT("employeeId") AS "numberOfEmployees"
FROM "Employee"
GROUP BY "age"
ORDER BY "age";

-- B2 <18>: Identify MAC Addresses of every computer in a branch.
SELECT "macAddress", "Branch"."name"
FROM "ComputerMachine"
         JOIN "Branch" ON "Branch"."branchId" = "ComputerMachine"."branchId";

-- B3 <7>: Identify the common availability of each menu. For example, a menu can only specifically available from anytime except 3 PM to 10 PM on Wednesday to Sunday.
SELECT "MR"."menuRefId",
       "MR"."nameTha",
       "MA"."dayOfWeek",
       "MA"."timeRangeStart",
       "MA"."timeRangeEnd"
FROM "MenuAvailability" "MA"
         JOIN "MenuRef" "MR" ON "MA"."menuRefId" = "MR"."menuRefId";

-- B4 <8>: Identify the duration it takes to complete each inventory supply inbound order.
SELECT *
FROM "InventoryInboundOrder" "IIO"
         JOIN "InventoryInboundOrderItem" "IIOI" ON "IIO"."inboundOrderId" = "IIOI"."inboundOrderId";

-- B5 <29>: List all employees' full name that has the age greater than or equal 40 years old.
SELECT "employeeId", CONCAT("firstname", ' ', "surname") AS "fullName", "age"
FROM "Employee"
WHERE "age" >= 40;

-- B6 <13>: List all gift voucher copies that are already used.
SELECT "GVT"."giftVoucherNo", "GVR"."name", "valueAmount"
FROM "GiftVoucherTransaction" "GVT"
         JOIN "GiftVoucher" "GV" ON "GV"."giftVoucherNo" = "GVT"."giftVoucherNo"
         JOIN "GiftVoucherRef" "GVR" ON "GV"."giftVoucherRefId" = "GVR"."giftVoucherRefId";

-- B7 <2>: List food items in salad bar that are needed to be refilled.
SELECT "SBR"."foodItemRefId", "FIR"."nameTha" "name", ("SBR"."quantity" || ' ' || "QUR"."name") "amount"
FROM "FoodItemRef" "FIR"
         JOIN "SaladBarRefill" "SBR" ON "FIR"."foodItemRefId" = "SBR"."foodItemRefId"
         JOIN "QuantityUnitRef" "QUR" ON "SBR"."quantityUnit" = "QUR"."quantityUnitRefId";

-- B8 <9>: List the details of all "western" food servings.
SELECT "servingRefId", "nameEng", "nameTha", "basePrice"
FROM "ServingRef"
WHERE "genre" = 'western';

-- B9 <10>: List the details of food items given a serving.
SELECT "ServingFoodItemRef"."servingRefId", "ServingRef"."nameEng", "FoodItemRef"."nameEng"
FROM "ServingRef"
         JOIN "ServingFoodItemRef" ON "ServingRef"."servingRefId" = "ServingFoodItemRef"."servingRefId"
         JOIN "FoodItemRef" ON "FoodItemRef"."foodItemRefId" = "ServingFoodItemRef"."foodItemRefId"
ORDER BY "servingRefId";

-- B10 <24>: List the details of seasonal menus.
SELECT "SeasonRef"."name", "nameTha", "descriptionTha"
FROM "MenuRef"
         JOIN "MenuSeasonRef" ON "MenuRef"."menuRefId" = "MenuSeasonRef"."menuRefId"
         JOIN "SeasonRef" ON "MenuSeasonRef"."seasonRefId" = "SeasonRef"."seasonRefId";

-- B11 <4>: List the worth of each gift voucher in each gift voucher transaction.
SELECT "GVT"."paymentTransactionId", "GVT"."giftVoucherNo", "name", "valueAmount"
FROM "GiftVoucherTransaction" "GVT"
         JOIN "GiftVoucher" "GV" ON "GVT"."giftVoucherNo" = "GV"."giftVoucherNo"
         JOIN "GiftVoucherRef" "GVR" ON "GV"."giftVoucherRefId" = "GVR"."giftVoucherRefId";

-- B12 <28>: Show all employees' address that are located in Chonburi
SELECT "E".*
FROM "Employee" "E"
         JOIN "Province" ON "E"."provinceId" = "Province"."provinceId"
WHERE "nameEnglish" = 'Chonburi Province';

-- B13 <25>: Show employees in each branch.
SELECT "employeeId", "firstname", "surname", "name"
FROM "Employee"
         JOIN "Branch" "B" ON "B"."branchId" = "Employee"."branchId";

-- B14 <17>: Show the assigned work time of every employee.
SELECT "EV"."employeeId",
       "firstname",
       "surname",
       "age",
       "workAtBranch",
       array_agg(ROW ("WT"."timeStart", "WT"."timeEnd", "dayOfWeek", ("timeEnd" - "timeStart"))) "workTime"
FROM "EmployeeView" "EV"
         JOIN "WorkTime" "WT" ON "EV"."employeeId" = "WT"."employeeId"
GROUP BY "EV"."employeeId", "firstname", "surname", "age", "workAtBranch";

-- B15 <6>: Show the availability time range of all seasonal menu.
SELECT "MR"."menuRefId",
       "MR"."nameEng",
       "SR"."name" "seasonName",
       "SR"."dateStart",
       "SR"."dateEnd"
FROM "SeasonRef" "SR"
         JOIN "MenuSeasonRef" "MSR" ON "SR"."seasonRefId" = "MSR"."seasonRefId"
         JOIN "MenuRef" "MR" ON "MR"."menuRefId" = "MSR"."menuRefId";

-- B16 <23>: Show the details of menu in each order.
SELECT "OrderItem"."orderId", "MenuRef"."nameTha", "MenuRef"."descriptionTha", "OrderItem"."perUnitPrice"
FROM "MenuRef"
         JOIN "OrderItem" ON "MenuRef"."menuRefId" = "OrderItem"."menuRefId";

-- B17 <27>: Show the salary of all Kitchen Managers
SELECT "wagePaymentAmount" * 30 AS "salary", "wageBonusAmount", "wagePaymentAmount" * 30 + "wageBonusAmount" AS "total"
FROM "EmployeeWagePayment"
         JOIN "KitchenManager" ON "EmployeeWagePayment"."employeeId" = "KitchenManager"."employeeId";
