--Show all GiftVoucher that is already used
SELECT "giftVoucherNo" FROM "GiftVoucherTransaction";

--Show a GiftVoucher Value in each GiftVoucherTransaction
SELECT "GiftVoucherTransaction"."paymentTransactionId", "GiftVoucherTransaction"."giftVoucherNo", "valueAmount" FROM "GiftVoucherTransaction"
    JOIN "GiftVoucher" ON "GiftVoucherTransaction"."giftVoucherNo" = "GiftVoucher"."giftVoucherNo"
    JOIN "GiftVoucherRef" ON "GiftVoucher"."giftVoucherRefId" = "GiftVoucherRef"."giftVoucherRefId";

--Show employee in each branch
SELECT "firstname", "surname", "name" FROM "Employee"
    JOIN "Branch" B on B."branchId" = "Employee"."branchId";

--Show detail of seasonal menu
SELECT * FROM "SeasonRef";

--Show ingredient in each food item
SELECT "FoodItemRef"."nameTha", "FoodIngredientRef"."nameTha", "quantity", "QuantityUnitRef"."name" FROM "FoodItemRef"
    JOIN "FoodItemIngredientRef" ON "FoodItemRef"."foodItemRefId" = "FoodItemIngredientRef"."foodItemRefId"
    JOIN "FoodIngredientRef" ON "FoodItemIngredientRef"."foodIngredientRef" = "FoodIngredientRef"."foodIngredientRefId"
    JOIN "QuantityUnitRef" ON "FoodItemIngredientRef"."quantityUnitRefId" = "QuantityUnitRef"."quantityUnitRefId";

--Show menu detail in each order
SELECT "OrderItem"."orderId", "MenuRef"."nameTha", "MenuRef"."descriptionTha", "OrderItem"."perUnitPrice" FROM "MenuRef"
    JOIN "OrderItem" ON "MenuRef"."menuRefId" = "OrderItem"."menuRefId";

--Show food items in salad bar that is refilled
SELECT "SaladBarRefill"."employeeId", "FoodItemRef"."nameTha", "SaladBarRefill".quantity, "QuantityUnitRef".name FROM "FoodItemRef"
    JOIN "SaladBarRefill" ON "FoodItemRef"."foodItemRefId" = "SaladBarRefill"."foodItemRefId"
    JOIN "QuantityUnitRef" ON "SaladBarRefill"."quantityUnit" = "QuantityUnitRef"."quantityUnitRefId";

--Show time start and time end of all MenuAvailability
SELECT "MenuRef"."nameTha", "MenuAvailability"."dayOfWeek", "MenuAvailability"."timeRangeStart", "MenuAvailability"."timeRangeEnd" FROM "MenuAvailability"
    JOIN "MenuRef" ON "MenuAvailability"."menuRefId" = "MenuRef"."menuRefId";

--Show all food items from a serving
SELECT "ServingFoodItemRef"."servingRefId", "ServingRef"."nameEng", "FoodItemRef"."nameEng" FROM "ServingRef"
    JOIN "ServingFoodItemRef" ON "ServingRef"."servingRefId" = "ServingFoodItemRef"."servingRefId"
    JOIN "FoodItemRef" ON "FoodItemRef"."foodItemRefId" = "ServingFoodItemRef"."foodItemRefId"
    ORDER BY "servingRefId";

--Show all number of customers in a day
SELECT "timeAdded"::DATE, SUM("totalCustomers") AS TotalInDay FROM "CustomerPax"
WHERE "timeAdded" BETWEEN '2020-02-08 00:00:00' AND '2020-02-08 23:59:59'
GROUP BY "timeAdded"::DATE;

--Show computer in each address
SELECT "macAddress", "Branch"."name" FROM "ComputerMachine"
    JOIN "Branch" ON "Branch"."branchId" = "ComputerMachine"."branchId";

--Show billing that has the highest total price in this month
SELECT MAX("amount") FROM "CashTransaction";

--Show count of time delivered InventoryInboundOrder
SELECT COUNT("inboundOrderId") FROM "InventoryInboundOrder";

--Show total distance that a delivery man delivered
SELECT "BillingDelivery"."deliveryManId", SUM("timeUsed") FROM "BillingDelivery"
    JOIN "DeliveryMan" ON "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
WHERE "BillingDelivery"."deliveryManId" = "DeliveryMan"."employeeId"
GROUP BY "BillingDelivery"."deliveryManId";

--Show salary of all Kitchen Managers
SELECT "wagePaymentAmount" * 30 AS "salary", "wageBonusAmount", "wagePaymentAmount" * 30 + "wageBonusAmount" AS total FROM "EmployeeWagePayment"
    JOIN "KitchenManager" ON "EmployeeWagePayment"."employeeId" = "KitchenManager"."employeeId";

--Show all employee address that is located in Chonburi
SELECT "fullAddress" FROM "Employee"
    JOIN "Province" ON "Employee"."provinceId" = "Province"."provinceId"
    WHERE "nameEnglish" = 'Chonburi Province';

--List all employee full name that age is more than 40 or equal
SELECT CONCAT("firstname", ' ', "surname") AS "fullName", age FROM "Employee"
    WHERE "age" >= 40;

--Identify creditTransaction that has the highest amount
SELECT * FROM "CreditTransaction"
    ORDER BY "amount" DESC
    LIMIT 1;

--Show cashTransaction that has the highest total price
SELECT * FROM "CashTransaction"
    ORDER BY "amount" DESC
    LIMIT 1;

--Count employee category by age
SELECT "age", COUNT("employeeId") FROM "Employee"
    GROUP BY "age"
    ORDER BY "age";

--Identify age that has the hightest number of employee
SELECT "age", COUNT("employeeId") FROM "Employee"
    GROUP BY "age"
    ORDER BY COUNT("employeeId") DESC
    LIMIT 1;

