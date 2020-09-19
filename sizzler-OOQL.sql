-- Bare extents
branches
saladBars
computerMachines
timeAttendanceMachines
employees
waiters
kitchenPorters
chefs
cashiers
kitchenManagers
deliveryMen
employeeWagePayments
branchManagers
clockInOuts
cashierMachines
customerPaxes
customerDeliveries
orders
workTimes
memberCustomers
customerRewardRedemption
memberLevelRefs
redeemableRewards
billings
billingOnSite
billingDelivery
cashierBillingHandlings
inventoryInboundOrders
cashTransactions
creditTransactions
giftVoucherTransactions
giftVoucherRefs
giftVouchers
orderItems
seasonRefs
menuAvailability
menuRefs
servingRefs
menuServingRefs
foodItemRefs
servingFoodItemRef
foodItemIngredientRefs
foodIngredientRefs
menuServingCustomizations
saladBarServings
saladBarRefills

-- 0: List all branches that are normally operational
DEFINE OperatingBranches AS
SELECT b
FROM b IN branches
WHERE b.status = 'normally operational';

-- 1: Get branches that is located in a given province name
DEFINE BranchesInProvince(provinceName) AS
SELECT b
FROM b IN OperatingBranches
WHERE b.address.province = provinceName;

-- 2: List every branch's name, province as well as telephone number
SELECT struct(name: b.name, province: b.address.province, telephoneNumbers: b.telephoneNumber)
FROM b IN OperatingBranches;

-- 3: List customers who registered themself close to a given branch name.
DEFINE CustomersWhoLocatedNearBranch(branchName) AS
SELECT [DISTINCT] b.locatedNear
FROM b IN OperatingBranches
WHERE b.name = branchName;

-- 4: Get every inventory order made by a given branch
DEFINE InventoryOrdersOfBranch(branchName) AS
SELECT [DISTINCT] b.manages
FROM b IN OperatingBranches
WHERE b.name = branchName;

-- 5: Get all servings of the salad bar in a given branch
DEFINE SaladServingOfBranch(branchName) AS
SELECT [DISTINCT] b.offersSaladBar.leadsTo
FROM b IN branches
WHERE b.name = branchName;

-- 6: List all employees who work for a given branch
DEFINED EmployeesWhoWorkForBranch(branchName) AS
SELECT [DISTINCT] b.operatedBy
FROM b IN branches
WHERE b.name = branchName;

-- 7: List employees who has an age lower than 18 years old
SELECT e
FROM e IN employees
WHERE (EXTRACT(YEAR FROM now()) - EXTRACT(YEAR FROM e.birthdate)) < 18;

-- 8: List employees who work over 3 days per week
SELECT e
FROM e IN employees
WHERE COUNT(e.workTimes) > 3;

-- 9: List employees who get paid more than the overall wage payment average
SELECT e
FROM e IN employees
WHERE e.float * 30 > (SELECT AVG(wagePaymentAmount) FROM e IN employees);

-- 10: List all employees who carry out salad bar refills along with the food item involved
SELECT e.carriesOut
FROM e IN employees

SELECT struct(employee: x.e, foodItems: x.e.carriesOut.refersTo)
FROM x IN (
    SELECT e
    FROM e IN employees
    WHERE e.carriesOut IS NOT NULL
);

-- 11: List all waiters who are fluent not only in Thai and English but also Chinese
SELECT w
FROM w IN waiters
WHERE 'Thai' IN w.languageFluency AND 'English' IN w.languageFluency AND 'Chinese' IN w.languageFluency;

-- 12: For each chef, list cooking roles that is in the highest priority along with the information of the respective chef.
SELECT  struct( c.employeeId,
                c.firstname,
                c.surname,
                highPriorityCookingRoles: (
                                    SELECT role
                                    FROM role IN c.cookingRole
                                    WHERE role.priority = 'high'))
FROM c in chefs;

-- 13: Identify the list of billing handled by a given Cashier employee Id
DEFINE BillingHandledBy(employeeId) AS
SELECT h.BillingOnSite
FROM h in (
    SELECT c.participates
    FROM c in cashiers
    WHERE c.employeeId = employeeId
);

-- 14: Find the average amount of payment that is handled by each employee
SELECT struct(
            cashierId,
            averageAmountOfHandledPayments: AVG(
                SELECT SUM((oi.perUnitPrice + oi.perUnitTakeHomeFee - oi.perUnitDiscount) * oi.quantity)
                FROM oi IN  (SELECT o.includes
                             FROM o in (SELECT p.cbh.needed.orders FROM p IN partition))
            )
)
FROM cbh IN cashierBillingHandlings
GROUP BY cashierId: cbh.participatedBy.employeeId;

-- 15: Count the number of issued Gift Vouchers from each Gift Voucher type
SELECT giftVoucherRefId, totalNumberOfIssuedVouchers: COUNT(partition)
FROM g IN giftVouchers
GROUP BY giftVoucherRefId: g.refersTo.giftVoucherRefId;

-- 16: For each Order, count the number of order items as well as the price of each
SELECT orderId,
        totalPrice: SUM(SELECT (oi.perUnitPrice + oi.perUnitTakeHomeFee - oi.perUnitDiscount) * oi.quantity FROM p IN partition),
        totalItemsInOrder: COUNT(partition)
FROM oi IN orderItems
GROUP BY orderId: oi.includedIn.orderId;

-- 17: Select food menus that are currently available to customers a given time and branchId.
DEFINE AvailableMenus(branchId, givenTime) AS
SELECT m
FROM m IN menuRefs
WHERE m.isActive IS TRUE AND
    EXISTS(
        SELECT ma
        FROM ma IN m.dependsOnAvailability
        WHERE EXTRACT(DAY_OF_WEEK FROM givenTime) = ma.dayOfWeek
                AND EXTRACT(TIME FROM givenTime) IS BETWEEN ma.timeRangeStart AND ma.timeRangeEnd)
    AND EXISTS(
        SELECT sr
        FROM sr IN n.dependsOnSeason
        WHERE givenTime IS BETWEEN sr.dateStart AND sr.dateEnd
    );