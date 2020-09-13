/**
 * SECTION: Declare Additional Libraries for types or functions
 */
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- DROP EXTENSION "citext";
-- DROP EXTENSION "uuid-ossp";

/**
 * SECTION: Begin Data Definition Language
 */
CREATE TABLE IF NOT EXISTS "Province"
(
    "provinceId"  SERIAL PRIMARY KEY,
    "nameThai"    VARCHAR(50) UNIQUE NOT NULL,
    "nameEnglish" VARCHAR(50) UNIQUE NOT NULL
);


-- SECTION: Branch

CREATE TYPE BRANCH_STATUS AS ENUM ('normally operational', 'under maintenance', 'out-of-business');

CREATE TABLE IF NOT EXISTS "Branch"
(
    "branchId"            UUID PRIMARY KEY            DEFAULT "uuid_generate_v4"(),
    "name"                VARCHAR(50) UNIQUE NOT NULL,
    "provinceId"          INT                NOT NULL REFERENCES "Province" ("provinceId"),
    "fullAddress"         TEXT               NOT NULL,
    "coordinateLatitude"  FLOAT              NOT NULL,
    "coordinateLongitude" FLOAT              NOT NULL,
    "email"               CITEXT             NOT NULL UNIQUE,
    "establishingDate"    DATE               NOT NULL DEFAULT now(),
    "status"              BRANCH_STATUS      NOT NULL DEFAULT 'under maintenance'
);

CREATE TABLE IF NOT EXISTS "Table"
(
    "branchId" UUID NOT NULL REFERENCES "Branch" ("branchId"),
    "tableId"  INT  NOT NULL,
    PRIMARY KEY ("branchId", "tableId")
);

CREATE TABLE IF NOT EXISTS "BranchTelephone"
(
    "branchId"    UUID NOT NULL
        REFERENCES "Branch" ("branchId") ON DELETE CASCADE,
    "telephoneNo" VARCHAR(15) UNIQUE,
    PRIMARY KEY ("branchId", "telephoneNo")
);

CREATE TYPE DAY_OF_WEEK AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

CREATE TABLE IF NOT EXISTS "BranchOpenTime"
(
    "branchId"    UUID
        REFERENCES "Branch" ("branchId") ON DELETE CASCADE,
    "dayOfWeek"   DAY_OF_WEEK NOT NULL,
    "timeOpening" TIME        NOT NULL,
    "timeClosing" TIME        NOT NULL,
    CONSTRAINT "Check_ClosingTimeIsGreaterThanOpeningTime" CHECK ( "timeClosing" > "timeOpening"),
    PRIMARY KEY ("branchId", "dayOfWeek")
);

/**
  Computer Machine belonged to a branch
 */
CREATE TABLE IF NOT EXISTS "ComputerMachine"
(
    "computerMachineId"   UUID PRIMARY KEY   DEFAULT "uuid_generate_v4"(),
    "macAddress"          MACADDR8 UNIQUE,
    "serialNumber"        VARCHAR(50) UNIQUE,
    "deploymentTimestamp" TIMESTAMP NOT NULL DEFAULT now(),
    "branchId"            UUID REFERENCES "Branch" ("branchId")
);

CREATE TABLE IF NOT EXISTS "TimeAttendanceMachine"
(
    "computerMachineId"             UUID PRIMARY KEY REFERENCES "ComputerMachine" ("computerMachineId"),
    "isSupportFingerprintBiometric" BOOL NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "CashierMachine"
(
    "computerMachineId" UUID PRIMARY KEY REFERENCES "ComputerMachine" ("computerMachineId")
);

CREATE TABLE IF NOT EXISTS "SaladBar"
(
    "saladBarId" UUID PRIMARY KEY DEFAULT "uuid_generate_v4"(),
    "branchId"   UUID
        REFERENCES "Branch" ("branchId") ON DELETE CASCADE
);

-- SECTION: Employee
CREATE TABLE IF NOT EXISTS "EducationLevelRef"
(
    "educationLevelId" SERIAL PRIMARY KEY,
    "nameThai"         VARCHAR(50) NOT NULL,
    "nameEnglish"      VARCHAR(50) NOT NULL
);

CREATE TYPE GENDER AS ENUM ('male', 'female');

CREATE OR REPLACE FUNCTION
    "calculatePersonAge"("birthday" DATE)
    RETURNS INT
AS
$CODE$
BEGIN
    RETURN extract(YEAR FROM CURRENT_DATE)
               - extract(YEAR FROM "birthday")
        + 1;
END
$CODE$
    LANGUAGE "plpgsql" IMMUTABLE;

CREATE TABLE IF NOT EXISTS "Employee"
(
    "employeeId"       UUID PRIMARY KEY                                        NOT NULL DEFAULT "uuid_generate_v4"(),
    "firstname"        VARCHAR(50)                                             NOT NULL,
    "surname"          VARCHAR(50)                                             NOT NULL,
    "nickname"         VARCHAR(20),
    "email"            CITEXT                                                  NOT NULL UNIQUE,
    "educationLevelId" INT REFERENCES "EducationLevelRef" ("educationLevelId") NOT NULL,
    "provinceId"       INT REFERENCES "Province" ("provinceId")                NOT NULL,
    "fullAddress"      TEXT                                                    NOT NULL,
    "gender"           GENDER                                                  NOT NULL,
    "citizenId"        VARCHAR(13) UNIQUE                                      NOT NULL,
    "joinDate"         DATE                                                    NOT NULL DEFAULT now(),
    "birthdate"        DATE                                                    NOT NULL
        CONSTRAINT "Check_JoinDateGreaterThanBirthdate" CHECK ( "birthdate" < "joinDate" ),
    "wage"             DECIMAL(12, 2)                                          NOT NULL
        CONSTRAINT "Check_ThaiMinimumWagePerDay" CHECK ( "wage" > 300 ),
    "branchId"         UUID                                                    NOT NULL REFERENCES "Branch" ("branchId"),
    "age"              INT GENERATED ALWAYS AS ("calculatePersonAge"("birthdate")) STORED
);

CREATE TABLE IF NOT EXISTS "EmployeeTelephone"
(
    "employeeId"  UUID PRIMARY KEY
        REFERENCES "Employee" ("employeeId") ON DELETE CASCADE,
    "telephoneNo" VARCHAR(15) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS "WorkTime"
(
    "workTimeId" SERIAL PRIMARY KEY,
    "dayOfWeek"  DAY_OF_WEEK NOT NULL,
    "timeStart"  TIME        NOT NULL,
    "timeEnd"    TIME        NOT NULL,
    "isPartTime" BOOL        NOT NULL DEFAULT FALSE,
    "employeeId" UUID        NOT NULL REFERENCES "Employee" ("employeeId")
);

CREATE TABLE IF NOT EXISTS "ClockInClockOut"
(
    "computerMachineId" UUID      NOT NULL REFERENCES "TimeAttendanceMachine" ("computerMachineId"),
    "employeeId"        UUID      NOT NULL REFERENCES "Employee" ("employeeId"),
    "clockInTimestamp"  TIMESTAMP NOT NULL DEFAULT now(),
    "clockOutTimestamp" TIMESTAMP NOT NULL DEFAULT now() + INTERVAL '6 hour',
    "workTimeId"        INT       NOT NULL REFERENCES "WorkTime" ("workTimeId"),
    PRIMARY KEY ("computerMachineId", "employeeId", "clockInTimestamp")
);

-- SECTION: Employee -> Waiter
CREATE TABLE IF NOT EXISTS "WorldLanguageRef"
(
    "worldLanguageRefId" SERIAL PRIMARY KEY,
    "name"               VARCHAR(30) UNIQUE NOT NULL,
    "alias"              VARCHAR(30) UNIQUE
);

CREATE TABLE IF NOT EXISTS "Waiter"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);

CREATE TABLE IF NOT EXISTS "WaiterLanguageFluency"
(
    "employeeId"         UUID NOT NULL REFERENCES "Waiter" ("employeeId"),
    "worldLanguageRefId" INT  NOT NULL REFERENCES "WorldLanguageRef" ("worldLanguageRefId"),
    PRIMARY KEY ("employeeId", "worldLanguageRefId")
);

-- SECTION: Employee -> Kitchen Porter
CREATE TABLE IF NOT EXISTS "KitchenPorter"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);

-- SECTION: Employee -> Chef
CREATE TABLE IF NOT EXISTS "CookingRoleRef"
(
    "cookingRoleRefId" SERIAL PRIMARY KEY,
    "name"             VARCHAR(30) NOT NULL UNIQUE,
    "description"      TEXT        NOT NULL
);

CREATE TABLE IF NOT EXISTS "Chef"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);

CREATE TYPE PRIORITY AS ENUM ('high', 'medium', 'low');

CREATE TABLE IF NOT EXISTS "ChefCookingRole"
(
    "employeeId"       UUID REFERENCES "Chef" ("employeeId"),
    "cookingRoleRefId" INT REFERENCES "CookingRoleRef" ("cookingRoleRefId"),
    "priority"         PRIORITY NOT NULL DEFAULT 'medium'
);

-- SECTION: Employee -> Cashier
CREATE TABLE IF NOT EXISTS "Cashier"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);

-- SECTION: Employee -> Kitchen Manager
CREATE TABLE IF NOT EXISTS "KitchenManager"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);


-- SECTION: Employee -> Delivery Man
CREATE TABLE IF NOT EXISTS "DeliveryMan"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);


-- SECTION: Employee -> Branch Manager
CREATE TABLE IF NOT EXISTS "BranchManager"
(
    "employeeId" UUID PRIMARY KEY REFERENCES "Employee" ("employeeId")
);

CREATE TABLE IF NOT EXISTS "EmployeeWagePayment"
(
    "employeeId"        UUID           NOT NULL REFERENCES "Employee" ("employeeId"),
    "wagePaymentAmount" DECIMAL(12, 2) NOT NULL,
    "wageBonusAmount"   DECIMAL(12, 2) NOT NULL,
    "timestamp"         TIMESTAMP      NOT NULL DEFAULT now(),
    "branchManagerId"   UUID           NOT NULL REFERENCES "BranchManager" ("employeeId"),
    PRIMARY KEY ("employeeId", "branchManagerId", "timestamp")
);


-- SECTION: Member Customer
CREATE TABLE IF NOT EXISTS "MemberCustomer"
(
    "memberCustomerId" UUID PRIMARY KEY DEFAULT "uuid_generate_v4"(),
    "firstname"        VARCHAR(50) NOT NULL,
    "surname"          VARCHAR(50) NOT NULL,
    "telephoneNo"      VARCHAR(15) NOT NULL UNIQUE,
    "birthdate"        DATE        NOT NULL,
    "hashPwd"          TEXT        NOT NULL,
    "salt"             TEXT        NOT NULL,
    "email"            CITEXT      NOT NULL UNIQUE,
    "liveNearBranchId" UUID        NOT NULL REFERENCES "Branch" ("branchId")
);

-- SECTION: Member Customer -> Redeemable Reward
CREATE TABLE IF NOT EXISTS "RedeemableRewardRef"
(
    "redeemableRewardRefId" UUID PRIMARY KEY     DEFAULT "uuid_generate_v4"(),
    "name"                  VARCHAR(50) NOT NULL,
    "description"           TEXT        NOT NULL,
    "basePointsRequired"    INT         NOT NULL,
    "isInUse"               BOOL        NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "MembershipRewardRedemption"
(
    "redeemableRewardRefId" UUID      NOT NULL REFERENCES "RedeemableRewardRef" ("redeemableRewardRefId"),
    "memberCustomerRefId"   UUID      NOT NULL REFERENCES "MemberCustomer" ("memberCustomerId"),
    "timestamp"             TIMESTAMP NOT NULL DEFAULT now(),
    "pointSpent"            INT       NOT NULL,
    PRIMARY KEY ("redeemableRewardRefId", "memberCustomerRefId", "timestamp")
);

-- SECTION: Member Customer -> Membership Level
CREATE TABLE IF NOT EXISTS "MemberLevelRef"
(
    "memberLevelRefId" UUID        NOT NULL PRIMARY KEY DEFAULT "uuid_generate_v4"(),
    "name"             VARCHAR(20) NOT NULL,
    "description"      TEXT        NOT NULL,
    "pointThreshold"   INT         NOT NULL
);

CREATE TABLE IF NOT EXISTS "MemberLevelRewardOffering"
(
    "memberLevelRefId"      UUID NOT NULL REFERENCES "MemberLevelRef" ("memberLevelRefId"),
    "redeemableRewardRefId" UUID NOT NULL REFERENCES "RedeemableRewardRef" ("redeemableRewardRefId")
);

-- SECTION: Billing
CREATE TABLE IF NOT EXISTS "Billing"
(
    "billingId"                UUID PRIMARY KEY   DEFAULT "uuid_generate_v4"(),
    "taxInvoiceId"             VARCHAR(20) UNIQUE,
    "timeCreated"              TIMESTAMP NOT NULL DEFAULT now(),
    "timePaid"                 TIMESTAMP,
    "timeCanceled"             TIMESTAMP,
    "involvedMemberCustomerId" UUID REFERENCES "MemberCustomer" ("memberCustomerId"),
    "pointReceived"            INT
        CONSTRAINT "Check_IffIsMemberAndReceivePoints" CHECK (
                ("involvedMemberCustomerId" IS NOT NULL AND "pointReceived" IS NOT NULL) OR
                ("involvedMemberCustomerId" IS NULL AND "pointReceived" IS NULL) ),
    "pointExpirationTime"      INTERVAL
        CONSTRAINT "Check_IfReceivePointsThenHasPointExpiration" CHECK (
                ("pointReceived" IS NOT NULL AND "pointExpirationTime" IS NOT NULL) OR
                ("pointReceived" IS NULL AND "pointExpirationTime" IS NULL) )
);

-- SECTION: Billing -> Subclasses of Billing
CREATE TABLE IF NOT EXISTS "BillingOnSite"
(
    "billingId" UUID PRIMARY KEY REFERENCES "Billing" ("billingId")
);

CREATE TABLE IF NOT EXISTS "BillingDelivery"
(
    "billingId"     UUID PRIMARY KEY REFERENCES "Billing" ("billingId"),
    "deliveryManId" UUID NOT NULL REFERENCES "DeliveryMan" ("employeeId"),
    "timeUsed"      INTERVAL,
    "distanceKM"    FLOAT
        CONSTRAINT "Check_IffThereAreDistanceAndTime" CHECK ( ("timeUsed" IS NULL AND "distanceKM" IS NULL) OR
                                                              ("timeUsed" IS NOT NULL AND "distanceKM" IS NOT NULL) )
);

CREATE TABLE IF NOT EXISTS "CashierBillingHandling"
(
    "cashierId"        UUID REFERENCES "Cashier" ("employeeId"),
    "cashierMachineId" UUID REFERENCES "CashierMachine" ("computerMachineId"),
    "billingId"        UUID REFERENCES "BillingOnSite" ("billingId"),
    PRIMARY KEY ("cashierId", "cashierMachineId", "billingId")
);

-- SECTION: Customer Instance
CREATE TABLE IF NOT EXISTS "CustomerInstance"
(
    "customerInstanceId" SERIAL PRIMARY KEY,
    "timeAdded"          TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "CustomerPax"
(
    "totalCustomers"  INT  NOT NULL DEFAULT 1,
    "tableId"         INT  NOT NULL,
    "tableBranchId"   UUID NOT NULL,
    "onSiteBillingId" UUID NOT NULL REFERENCES "BillingOnSite" ("billingId"),
    PRIMARY KEY ("customerInstanceId"),
    FOREIGN KEY ("tableId", "tableBranchId")
        REFERENCES "Table" ("tableId", "branchId")
) INHERITS ("CustomerInstance");

CREATE TABLE IF NOT EXISTS "CustomerDelivery"
(
    "telephoneNo"       VARCHAR(15) NOT NULL,
    "fullAddress"       TEXT        NOT NULL,
    "provinceId"        INT         NOT NULL REFERENCES "Province" ("provinceId"),
    "deliveryBillingId" UUID        NOT NULL REFERENCES "BillingDelivery" ("billingId"),
    "handlingBranchId"  UUID        NOT NULL REFERENCES "Branch" ("branchId"),
    PRIMARY KEY ("customerInstanceId")
) INHERITS ("CustomerInstance");

-- SECTION: Customer Instance -> Order
CREATE TABLE IF NOT EXISTS "Order"
(
    "orderId"                    SERIAL PRIMARY KEY,
    "timeCreated"                TIMESTAMP NOT NULL DEFAULT now(),
    "note"                       TEXT,
    "customerPaxInstanceId"      INT REFERENCES "CustomerPax" ("customerInstanceId"),
    "customerDeliveryInstanceId" INT REFERENCES "CustomerDelivery" ("customerInstanceId"),
    "waiterId"                   UUID      NOT NULL REFERENCES "Waiter" ("employeeId"),
    "billingId"                  UUID      NOT NULL REFERENCES "Billing" ("billingId"),
    CONSTRAINT "Check_EitherCustomerPaxOrCustomerDelivery" CHECK (
            ("customerPaxInstanceId" IS NOT NULL AND "customerDeliveryInstanceId" IS NULL) OR
            ("customerPaxInstanceId" IS NULL AND "customerDeliveryInstanceId" IS NOT NULL))
);

-- SECTION: Billing -> PaymentTransaction
CREATE TABLE IF NOT EXISTS "PaymentTransaction"
(
    "paymentTransactionId" UUID PRIMARY KEY,
    "timestamp"            TIMESTAMP NOT NULL DEFAULT now(),
    "billingId"            UUID      NOT NULL REFERENCES "Billing" ("billingId")
);

CREATE TABLE IF NOT EXISTS "GiftVoucherRef"
(
    "giftVoucherRefId" SERIAL PRIMARY KEY,
    "name"             VARCHAR(60) NOT NULL,
    "description"      TEXT        NOT NULL,
    "timeAdded"        TIMESTAMP   NOT NULL DEFAULT now(),
    "timeCanceled"     TIMESTAMP,
    "valueAmount"      INT         NOT NULL,
    "lifetime"         INTERVAL             DEFAULT '5 years'
);

CREATE TABLE IF NOT EXISTS "GiftVoucher"
(
    "giftVoucherNo"    SERIAL PRIMARY KEY,
    "timeIssued"       TIMESTAMP NOT NULL DEFAULT now(),
    "giftVoucherRefId" INT       NOT NULL REFERENCES "GiftVoucherRef" ("giftVoucherRefId")
);

CREATE TABLE IF NOT EXISTS "CashTransaction"
(
    "paymentTransactionId" UUID PRIMARY KEY REFERENCES "PaymentTransaction" ("paymentTransactionId"),
    "amount"               DECIMAL(12, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS "CreditTransaction"
(
    "paymentTransactionId" UUID PRIMARY KEY REFERENCES "PaymentTransaction" ("paymentTransactionId"),
    "cardNumber"           VARCHAR(25)    NOT NULL,
    "amount"               DECIMAL(12, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS "GiftVoucherTransaction"
(
    "paymentTransactionId" UUID PRIMARY KEY REFERENCES "PaymentTransaction" ("paymentTransactionId"),
    "giftVoucherNo"        INT NOT NULL REFERENCES "GiftVoucher" ("giftVoucherNo")
);


-- SECTION: Food Ingredient Reference
CREATE TYPE FOOD_INGREDIENT_CATEGORY AS ENUM ('meat', 'vegetable', 'spice', 'sauce', 'desert', 'beverage', 'fruit', 'snack');

CREATE TABLE IF NOT EXISTS "FoodIngredientRef"
(
    "foodIngredientRefId" SERIAL PRIMARY KEY,
    "nameEng"             VARCHAR(50)              NOT NULL,
    "nameTha"             VARCHAR(50)              NOT NULL,
    "description"         TEXT,
    "category"            FOOD_INGREDIENT_CATEGORY NOT NULL
);

-- SECTION: Food Ingredient -> Inventory Inbound Order
CREATE TABLE IF NOT EXISTS "InventoryInboundOrder"
(
    "inboundOrderId"           SERIAL PRIMARY KEY,
    "timeCreated"              TIMESTAMP NOT NULL DEFAULT now(),
    "timeCanceled"             TIMESTAMP,
    "note"                     TEXT,
    "deliveryIn"               INTERVAL  NOT NULL DEFAULT '12 hours',
    "managingKitchenManagerId" UUID      NOT NULL REFERENCES "KitchenManager" ("employeeId")
);

-- Quantity (weight, volume) Unit Reference
CREATE TYPE QUANTITY_CATEGORY AS ENUM ('volume', 'weight', 'pack');

CREATE TABLE IF NOT EXISTS "QuantityUnitRef"
(
    "quantityUnitRefId" SERIAL PRIMARY KEY,
    "name"              VARCHAR(30)       NOT NULL UNIQUE,
    "abbreviation"      VARCHAR(30)       NOT NULL UNIQUE,
    "category"          QUANTITY_CATEGORY NOT NULL
);

CREATE TABLE IF NOT EXISTS "InventoryInboundOrderItem"
(
    "inboundOrderItemId"  SERIAL         NOT NULL,
    "verificationTime"    TIMESTAMP,
    "inboundOrderId"      INT            NOT NULL,
    "branchId"            UUID           NOT NULL REFERENCES "Branch" ("branchId"),
    "foodIngredientRefId" INT            NOT NULL REFERENCES "FoodIngredientRef" ("foodIngredientRefId"),
    "quantity"            FLOAT          NOT NULL DEFAULT 0,
    "quantityUnitRefId"   INT            NOT NULL REFERENCES "QuantityUnitRef" ("quantityUnitRefId"),
    "pricePerUnit"        DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY ("inboundOrderId", "inboundOrderItemId")
);

-- SECTION: Food Item Reference
CREATE TABLE IF NOT EXISTS "FoodItemRef"
(
    "foodItemRefId"  SERIAL PRIMARY KEY,
    "nameEng"        VARCHAR(50) NOT NULL,
    "nameTha"        VARCHAR(50) NOT NULL,
    "descriptionTha" TEXT,
    "descriptionEng" TEXT
);

-- Many-to-many relationship between FoodItemRef and FoodIngredientRef
CREATE TABLE IF NOT EXISTS "FoodItemIngredientRef"
(
    "foodItemRefId"     INT   NOT NULL REFERENCES "FoodItemRef" ("foodItemRefId"),
    "foodIngredientRef" INT   NOT NULL REFERENCES "FoodIngredientRef" ("foodIngredientRefId"),
    "quantity"          FLOAT NOT NULL,
    "quantityUnitRefId" INT   NOT NULL REFERENCES "QuantityUnitRef" ("quantityUnitRefId"),
    PRIMARY KEY ("foodItemRefId", "foodIngredientRef")
);

-- SECTION: Serving Reference
CREATE TYPE SERVING_GENRE AS ENUM ('australia', 'asian', 'western');

CREATE TABLE IF NOT EXISTS "ServingRef"
(
    "servingRefId"    SERIAL PRIMARY KEY,
    "nameEng"         VARCHAR(50)    NOT NULL,
    "nameTha"         VARCHAR(50)    NOT NULL,
    "descriptionTha"  TEXT,
    "descriptionEng"  TEXT,
    "genre"           SERVING_GENRE,
    "basePrice"       DECIMAL(12, 2) NOT NULL,
    "dateAdded"       DATE           NOT NULL DEFAULT now(),
    "hasFreeSaladBar" BOOL           NOT NULL
);

-- Many-to-many relationship between FoodItemRef and ServingRef
CREATE TABLE IF NOT EXISTS "ServingFoodItemRef"
(
    "servingRefId"      INT   NOT NULL,
    "foodItemRefId"     INT   NOT NULL,
    "quantity"          FLOAT NOT NULL,
    "quantityUnitRefId" INT   NOT NULL REFERENCES "QuantityUnitRef" ("quantityUnitRefId"),
    "isCustomization"   BOOL  NOT NULL DEFAULT FALSE,
    PRIMARY KEY ("servingRefId", "foodItemRefId")
);

-- SECTION: Serving Reference -> Subclasses
CREATE TYPE FOOD_TYPE AS ENUM ('steak', 'double steaks', 'burger', 'salad', 'rice', 'spaghetti', 'wrap', 'sandwich');

CREATE TABLE IF NOT EXISTS "Food"
(
    "servingRefId"       INT PRIMARY KEY REFERENCES "ServingRef" ("servingRefId"),
    "cookingDescription" TEXT,
    "type"               FOOD_TYPE NOT NULL,
    "isForChildren"      BOOL      NOT NULL DEFAULT FALSE,
    "isAppetizer"        BOOL      NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "Beverage"
(
    "servingRefId" INT PRIMARY KEY REFERENCES "ServingRef" ("servingRefId"),
    "volumeOz"     FLOAT NOT NULL,
    "isRefillable" BOOL  NOT NULL DEFAULT FALSE
);

-- SECTION: Menu Reference
CREATE TABLE IF NOT EXISTS "MenuRef"
(
    "menuRefId"      SERIAL PRIMARY KEY,
    "nameEng"        VARCHAR(30) NOT NULL,
    "nameTha"        VARCHAR(30) NOT NULL,
    "descriptionTha" TEXT,
    "descriptionEng" TEXT,
    "dateAdded"      DATE        NOT NULL DEFAULT now(),
    "isActive"       BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS "MenuServingRef"
(
    "menuRefId"        INT            NOT NULL REFERENCES "MenuRef" ("menuRefId"),
    "servingRefId"     INT            NOT NULL REFERENCES "ServingRef" ("servingRefId"),
    "realPrice"        DECIMAL(12, 2) NOT NULL,
    "pricingTimestamp" TIMESTAMP      NOT NULL DEFAULT now(),
    PRIMARY KEY ("menuRefId", "servingRefId")
);

-- SECTION: Order -> Order Item
CREATE TABLE IF NOT EXISTS "OrderItem"
(
    "orderItemId"        SERIAL         NOT NULL PRIMARY KEY,
    "orderId"            INT            NOT NULL REFERENCES "Order" ("orderId"),
    "menuRefId"          INT            NOT NULL REFERENCES "MenuRef" ("menuRefId"),
    "quantity"           INT            NOT NULL DEFAULT 1,
    "timeStarted"        TIMESTAMP      NOT NULL DEFAULT now(),
    "timeServed"         TIMESTAMP      NOT NULL
        CONSTRAINT "Check_ServeTimeLaterStartingTime" CHECK ( "timeServed" > "timeStarted" ),
    "perUnitPrice"       DECIMAL(12, 2) NOT NULL,
    "perUnitDiscount"    DECIMAL(12, 2) NOT NULL,
    "perUnitTakeHomeFee" DECIMAL(12, 2) NOT NULL,
    "isRefunded"         BOOL           NOT NULL DEFAULT FALSE,
    "price"              DECIMAL(12, 2) GENERATED ALWAYS AS ( ("perUnitPrice" + "perUnitTakeHomeFee" - "perUnitDiscount") * "quantity") STORED
);

-- SECTION 3-ary relationship "MenuServingCustomization"
CREATE TABLE IF NOT EXISTS "MenuServingCustomization"
(
    "orderItemId"              INT NOT NULL REFERENCES "OrderItem" ("orderItemId"),
    "replacedServingRefId"     INT NOT NULL,
    "replacedFoodItemRefId"    INT NOT NULL,
    "replacementFoodItemRefId" INT NOT NULL REFERENCES "FoodItemRef" ("foodItemRefId"),
    FOREIGN KEY ("replacedServingRefId", "replacedFoodItemRefId")
        REFERENCES "ServingFoodItemRef" ("servingRefId", "foodItemRefId"),
    PRIMARY KEY ("orderItemId", "replacedServingRefId", "replacedFoodItemRefId", "replacementFoodItemRefId")
);

-- SECTION: Menu Season & Availability
CREATE TABLE IF NOT EXISTS "SeasonRef"
(
    "seasonRefId" SERIAL      NOT NULL PRIMARY KEY,
    "name"        VARCHAR(30) NOT NULL,
    "dateStart"   TIMESTAMP   NOT NULL,
    "dateEnd"     TIMESTAMP   NOT NULL,
    CONSTRAINT "Check_DateEndComeAfterDateStart" CHECK ( "dateStart" < "dateEnd" )
);

CREATE TABLE IF NOT EXISTS "MenuSeasonRef"
(
    "seasonRefId" INT NOT NULL REFERENCES "SeasonRef" ("seasonRefId"),
    "menuRefId"   INT NOT NULL REFERENCES "MenuRef" ("menuRefId"),
    PRIMARY KEY ("seasonRefId", "menuRefId")
);

CREATE TABLE IF NOT EXISTS "MenuAvailability"
(
    "menuAvailabilityId" INT         NOT NULL PRIMARY KEY,
    "dayOfWeek"           DAY_OF_WEEK NOT NULL,
    "timeRangeStart"      TIME        NOT NULL,
    "timeRangeEnd"        TIME        NOT NULL,
    "menuRefId"           INT         NOT NULL REFERENCES "MenuRef" ("menuRefId")
        CONSTRAINT "Check_TimeEndComeAfterTimeStart" CHECK ( "timeRangeStart" < "timeRangeEnd" )
);

CREATE TABLE IF NOT EXISTS "SaladBarServing"
(
    "saladBarId"      UUID  NOT NULL REFERENCES "SaladBar" ("saladBarId"),
    "foodItemRefId"   INT   NOT NULL REFERENCES "FoodItemRef" ("foodItemRefId"),
    "maxQuantity"     FLOAT NOT NULL,
    "maxQuantityUnit" INT   NOT NULL REFERENCES "QuantityUnitRef" ("quantityUnitRefId"),
    PRIMARY KEY ("saladBarId", "foodItemRefId")
);

CREATE TABLE IF NOT EXISTS "SaladBarRefill"
(
    "employeeId"    UUID  NOT NULL REFERENCES "Employee" ("employeeId"),
    "saladBarId"    UUID  NOT NULL,
    "foodItemRefId" INT   NOT NULL,
    "quantity"      FLOAT NOT NULL,
    "quantityUnit"  INT REFERENCES "QuantityUnitRef" ("quantityUnitRefId"),
    FOREIGN KEY ("saladBarId", "foodItemRefId")
        REFERENCES "SaladBarServing" ("saladBarId", "foodItemRefId")
);