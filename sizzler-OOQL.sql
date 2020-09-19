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

-- 4: Get every inventory order made by a given branch.
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

-- 8: List employees who work over 3 days per week.
SELECT e
FROM e IN employees
WHERE COUNT(e.workTimes) > 3;

