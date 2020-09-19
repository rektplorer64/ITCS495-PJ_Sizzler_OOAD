-- 13: Show all GiftVoucher that is already used
SELECT "giftVoucherNo" FROM "GiftVoucherTransaction";

-- 4: Show a GiftVoucher Value in each GiftVoucherTransaction
SELECT "GiftVoucherTransaction"."paymentTransactionId", "GiftVoucherTransaction"."giftVoucherNo", "valueAmount" FROM "GiftVoucherTransaction"
    JOIN "GiftVoucher" ON "GiftVoucherTransaction"."giftVoucherNo" = "GiftVoucher"."giftVoucherNo"
    JOIN "GiftVoucherRef" ON "GiftVoucher"."giftVoucherRefId" = "GiftVoucherRef"."giftVoucherRefId";

-- 25: Show employee in each branch
SELECT "firstname", "surname", "name" FROM "Employee"
    JOIN "Branch" B on B."branchId" = "Employee"."branchId";

-- 24: Show detail of seasonal menu
SELECT "SeasonRef"."name", "nameTha", "descriptionTha" FROM "MenuRef"
    JOIN "MenuSeasonRef" ON "MenuRef"."menuRefId" = "MenuSeasonRef"."menuRefId"
    JOIN "SeasonRef" ON "MenuSeasonRef"."seasonRefId" = "SeasonRef"."seasonRefId";

-- 22: Show food ingredient in each food item
SELECT "FoodItemRef"."nameTha", "FoodIngredientRef"."nameTha", "quantity", "QuantityUnitRef"."name" FROM "FoodItemRef"
    JOIN "FoodItemIngredientRef" ON "FoodItemRef"."foodItemRefId" = "FoodItemIngredientRef"."foodItemRefId"
    JOIN "FoodIngredientRef" ON "FoodItemIngredientRef"."foodIngredientRef" = "FoodIngredientRef"."foodIngredientRefId"
    JOIN "QuantityUnitRef" ON "FoodItemIngredientRef"."quantityUnitRefId" = "QuantityUnitRef"."quantityUnitRefId";

-- 23: Show menu detail in each order
SELECT "OrderItem"."orderId", "MenuRef"."nameTha", "MenuRef"."descriptionTha", "OrderItem"."perUnitPrice" FROM "MenuRef"
    JOIN "OrderItem" ON "MenuRef"."menuRefId" = "OrderItem"."menuRefId";

-- 2: Show food items in salad bar that is refilled
SELECT "SaladBarRefill"."employeeId", "FoodItemRef"."nameTha", "SaladBarRefill".quantity, "QuantityUnitRef".name FROM "FoodItemRef"
    JOIN "SaladBarRefill" ON "FoodItemRef"."foodItemRefId" = "SaladBarRefill"."foodItemRefId"
    JOIN "QuantityUnitRef" ON "SaladBarRefill"."quantityUnit" = "QuantityUnitRef"."quantityUnitRefId";

-- 7: Show menu, time start, and time end of all MenuAvailability
SELECT "MenuRef"."nameTha", "MenuAvailability"."dayOfWeek", "MenuAvailability"."timeRangeStart", "MenuAvailability"."timeRangeEnd" FROM "MenuAvailability"
    JOIN "MenuRef" ON "MenuAvailability"."menuRefId" = "MenuRef"."menuRefId";

-- 10: Show all food items from a serving
SELECT "ServingFoodItemRef"."servingRefId", "ServingRef"."nameEng", "FoodItemRef"."nameEng" FROM "ServingRef"
    JOIN "ServingFoodItemRef" ON "ServingRef"."servingRefId" = "ServingFoodItemRef"."servingRefId"
    JOIN "FoodItemRef" ON "FoodItemRef"."foodItemRefId" = "ServingFoodItemRef"."foodItemRefId"
    ORDER BY "servingRefId";

-- 14: Show all number of customers in a day
SELECT "timeAdded"::DATE, SUM("totalCustomers") AS TotalInDay FROM "CustomerPax"
WHERE "timeAdded" BETWEEN '2020-02-08 00:00:00' AND '2020-02-08 23:59:59'
GROUP BY "timeAdded"::DATE;

-- 18: Show computer MAC ADDRESS in each branch
SELECT "macAddress", "Branch"."name" FROM "ComputerMachine"
    JOIN "Branch" ON "Branch"."branchId" = "ComputerMachine"."branchId";

-- 8: Show count of time delivered InventoryInboundOrder
SELECT COUNT("inboundOrderId") AS TotalInboundDeliveryCount FROM "InventoryInboundOrder";

-- 26: Show total distance that a delivery man delivered
SELECT "BillingDelivery"."deliveryManId", SUM("distanceKM") AS TotalDistance FROM "BillingDelivery"
    JOIN "DeliveryMan" ON "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
WHERE "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
GROUP BY "BillingDelivery"."deliveryManId";

-- 27: Show salary of all Kitchen Managers
SELECT "wagePaymentAmount" * 30 AS "salary", "wageBonusAmount", "wagePaymentAmount" * 30 + "wageBonusAmount" AS total FROM "EmployeeWagePayment"
    JOIN "KitchenManager" ON "EmployeeWagePayment"."employeeId" = "KitchenManager"."employeeId";

-- 28: Show all employee address that is located in Chonburi
SELECT "fullAddress" FROM "Employee"
    JOIN "Province" ON "Employee"."provinceId" = "Province"."provinceId"
    WHERE "nameEnglish" = 'Chonburi Province';

-- 29: List all employee full name that age is more than 40 or equal
SELECT CONCAT("firstname", ' ', "surname") AS "fullName", age FROM "Employee"
    WHERE "age" >= 40;

-- 31: Identify creditTransaction that has the highest amount
SELECT * FROM "CreditTransaction"
    ORDER BY "amount" DESC
    LIMIT 1;

-- 1: Show cashTransaction that has the highest total price
SELECT * FROM "CashTransaction"
    ORDER BY "amount" DESC
    LIMIT 1;

-- 33: Count employee category by age
SELECT "age", COUNT("employeeId") AS NumberOfEmployee FROM "Employee"
    GROUP BY "age"
    ORDER BY "age";

-- 34: Identify age that has the hightest number of employee
SELECT "age", COUNT("employeeId") AS NumberOfEmployee FROM "Employee"
    GROUP BY "age"
    ORDER BY COUNT("employeeId") DESC
    LIMIT 1;

-- 37: Show all menu sell count
SELECT "nameEng", COUNT("quantity") AS "sellCount" FROM "MenuRef"
    JOIN "OrderItem" ON "MenuRef"."menuRefId" = "OrderItem"."menuRefId"
    GROUP BY "nameEng"
    ORDER BY COUNT("quantity") DESC;

-- 35: Count all member customer that group by member level
SELECT "MemberLevelRef"."name", COUNT("memberCustomerId") AS "NumberOfMember" FROM "MemberCustomer"
    JOIN "MembershipRewardRedemption" ON "MemberCustomer"."memberCustomerId" = "MembershipRewardRedemption"."memberCustomerRefId"
    JOIN "MemberLevelRewardOffering" ON "MemberLevelRewardOffering"."redeemableRewardRefId" = "MembershipRewardRedemption"."redeemableRewardRefId"
    JOIN "MemberLevelRef" ON "MemberLevelRewardOffering"."memberLevelRefId" = "MemberLevelRef"."memberLevelRefId"
    GROUP BY "MemberLevelRef"."name";

-- 36: Show customer firstname, surname, and member level
SELECT "MemberCustomer"."firstname", "MemberCustomer"."surname", "MemberLevelRef"."name" FROM "MemberLevelRef"
    JOIN "MemberLevelRewardOffering" ON "MemberLevelRef"."memberLevelRefId" = "MemberLevelRewardOffering"."memberLevelRefId"
    JOIN "MembershipRewardRedemption" ON "MemberLevelRewardOffering"."redeemableRewardRefId" = "MembershipRewardRedemption"."redeemableRewardRefId"
    JOIN "MemberCustomer" ON "MemberCustomer"."memberCustomerId" = "MembershipRewardRedemption"."memberCustomerRefId";

