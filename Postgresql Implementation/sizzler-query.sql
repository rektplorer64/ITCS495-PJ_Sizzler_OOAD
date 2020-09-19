--13Show all GiftVoucher that is already used
SELECT "giftVoucherNo" FROM "GiftVoucherTransaction";

--4Show a GiftVoucher Value in each GiftVoucherTransaction
SELECT "GiftVoucherTransaction"."paymentTransactionId", "GiftVoucherTransaction"."giftVoucherNo", "valueAmount" FROM "GiftVoucherTransaction"
    JOIN "GiftVoucher" ON "GiftVoucherTransaction"."giftVoucherNo" = "GiftVoucher"."giftVoucherNo"
    JOIN "GiftVoucherRef" ON "GiftVoucher"."giftVoucherRefId" = "GiftVoucherRef"."giftVoucherRefId";

--25Show employee in each branch
SELECT "firstname", "surname", "name" FROM "Employee"
    JOIN "Branch" B on B."branchId" = "Employee"."branchId";

--24Show detail of seasonal menu
SELECT "SeasonRef"."name", "nameTha", "descriptionTha" FROM "MenuRef"
    JOIN "MenuSeasonRef" ON "MenuRef"."menuRefId" = "MenuSeasonRef"."menuRefId"
    JOIN "SeasonRef" ON "MenuSeasonRef"."seasonRefId" = "SeasonRef"."seasonRefId";

--22Show food ingredient in each food item
SELECT "FoodItemRef"."nameTha", "FoodIngredientRef"."nameTha", "quantity", "QuantityUnitRef"."name" FROM "FoodItemRef"
    JOIN "FoodItemIngredientRef" ON "FoodItemRef"."foodItemRefId" = "FoodItemIngredientRef"."foodItemRefId"
    JOIN "FoodIngredientRef" ON "FoodItemIngredientRef"."foodIngredientRef" = "FoodIngredientRef"."foodIngredientRefId"
    JOIN "QuantityUnitRef" ON "FoodItemIngredientRef"."quantityUnitRefId" = "QuantityUnitRef"."quantityUnitRefId";

--23Show menu detail in each order
SELECT "OrderItem"."orderId", "MenuRef"."nameTha", "MenuRef"."descriptionTha", "OrderItem"."perUnitPrice" FROM "MenuRef"
    JOIN "OrderItem" ON "MenuRef"."menuRefId" = "OrderItem"."menuRefId";

--2Show food items in salad bar that is refilled
SELECT "SaladBarRefill"."employeeId", "FoodItemRef"."nameTha", "SaladBarRefill".quantity, "QuantityUnitRef".name FROM "FoodItemRef"
    JOIN "SaladBarRefill" ON "FoodItemRef"."foodItemRefId" = "SaladBarRefill"."foodItemRefId"
    JOIN "QuantityUnitRef" ON "SaladBarRefill"."quantityUnit" = "QuantityUnitRef"."quantityUnitRefId";

--7Show menu, time start, and time end of all MenuAvailability
SELECT "MenuRef"."nameTha", "MenuAvailability"."dayOfWeek", "MenuAvailability"."timeRangeStart", "MenuAvailability"."timeRangeEnd" FROM "MenuAvailability"
    JOIN "MenuRef" ON "MenuAvailability"."menuRefId" = "MenuRef"."menuRefId";

--10Show all food items from a serving
SELECT "ServingFoodItemRef"."servingRefId", "ServingRef"."nameEng", "FoodItemRef"."nameEng" FROM "ServingRef"
    JOIN "ServingFoodItemRef" ON "ServingRef"."servingRefId" = "ServingFoodItemRef"."servingRefId"
    JOIN "FoodItemRef" ON "FoodItemRef"."foodItemRefId" = "ServingFoodItemRef"."foodItemRefId"
    ORDER BY "servingRefId";

--14Show all number of customers in a day
SELECT "timeAdded"::DATE, SUM("totalCustomers") AS TotalInDay FROM "CustomerPax"
WHERE "timeAdded" BETWEEN '2020-02-08 00:00:00' AND '2020-02-08 23:59:59'
GROUP BY "timeAdded"::DATE;

--18Show computer MAC ADDRESS in each branch
SELECT "macAddress", "Branch"."name" FROM "ComputerMachine"
    JOIN "Branch" ON "Branch"."branchId" = "ComputerMachine"."branchId";

--8Show count of time delivered InventoryInboundOrder
SELECT COUNT("inboundOrderId") AS TotalInboundDeliveryCount FROM "InventoryInboundOrder";

--26Show total distance that a delivery man delivered
SELECT "BillingDelivery"."deliveryManId", SUM("distanceKM") AS TotalDistance FROM "BillingDelivery"
    JOIN "DeliveryMan" ON "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
WHERE "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
GROUP BY "BillingDelivery"."deliveryManId";

--27Show salary of all Kitchen Managers
SELECT "wagePaymentAmount" * 30 AS "salary", "wageBonusAmount", "wagePaymentAmount" * 30 + "wageBonusAmount" AS total FROM "EmployeeWagePayment"
    JOIN "KitchenManager" ON "EmployeeWagePayment"."employeeId" = "KitchenManager"."employeeId";

--28Show all employee address that is located in Chonburi
SELECT "fullAddress" FROM "Employee"
    JOIN "Province" ON "Employee"."provinceId" = "Province"."provinceId"
    WHERE "nameEnglish" = 'Chonburi Province';

--29List all employee full name that age is more than 40 or equal
SELECT CONCAT("firstname", ' ', "surname") AS "fullName", age FROM "Employee"
    WHERE "age" >= 40;

--31Identify creditTransaction that has the highest amount
SELECT * FROM "CreditTransaction"
    ORDER BY "amount" DESC
    LIMIT 1;

--1 Show cashTransaction that has the highest total price
SELECT * FROM "CashTransaction"
    ORDER BY "amount" DESC
    LIMIT 1;

--33Count employee category by age
SELECT "age", COUNT("employeeId") AS NumberOfEmployee FROM "Employee"
    GROUP BY "age"
    ORDER BY "age";

--34Identify age that has the hightest number of employee
SELECT "age", COUNT("employeeId") AS NumberOfEmployee FROM "Employee"
    GROUP BY "age"
    ORDER BY COUNT("employeeId") DESC
    LIMIT 1;

--37Show all menu sell count
SELECT "nameEng", COUNT("quantity") AS "sellCount" FROM "MenuRef"
    JOIN "OrderItem" ON "MenuRef"."menuRefId" = "OrderItem"."menuRefId"
    GROUP BY "nameEng"
    ORDER BY COUNT("quantity") DESC;

--35Count all member customer that group by member level
SELECT "MemberLevelRef"."name", COUNT("memberCustomerId") AS "NumberOfMember" FROM "MemberCustomer"
    JOIN "MembershipRewardRedemption" ON "MemberCustomer"."memberCustomerId" = "MembershipRewardRedemption"."memberCustomerRefId"
    JOIN "MemberLevelRewardOffering" ON "MemberLevelRewardOffering"."redeemableRewardRefId" = "MembershipRewardRedemption"."redeemableRewardRefId"
    JOIN "MemberLevelRef" ON "MemberLevelRewardOffering"."memberLevelRefId" = "MemberLevelRef"."memberLevelRefId"
    GROUP BY "MemberLevelRef"."name";

--36Show customer firstname, surname, and member level
SELECT "MemberCustomer"."firstname", "MemberCustomer"."surname", "MemberLevelRef"."name" FROM "MemberLevelRef"
    JOIN "MemberLevelRewardOffering" ON "MemberLevelRef"."memberLevelRefId" = "MemberLevelRewardOffering"."memberLevelRefId"
    JOIN "MembershipRewardRedemption" ON "MemberLevelRewardOffering"."redeemableRewardRefId" = "MembershipRewardRedemption"."redeemableRewardRefId"
    JOIN "MemberCustomer" ON "MemberCustomer"."memberCustomerId" = "MembershipRewardRedemption"."memberCustomerRefId";

