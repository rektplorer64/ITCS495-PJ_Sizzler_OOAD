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
