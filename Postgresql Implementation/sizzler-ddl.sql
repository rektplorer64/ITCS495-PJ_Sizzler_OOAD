BEGIN;
COMMIT;
ROLLBACK;

CREATE DATABASE "MainSizzlerDb2";
SET search_path = "MainSizzlerDb2";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

CREATE TABLE IF NOT EXISTS "Province"
(
    "provinceId"  SERIAL PRIMARY KEY,
    "nameThai"    VARCHAR(50) UNIQUE NOT NULL,
    "nameEnglish" VARCHAR(50) UNIQUE NOT NULL
);

CREATE TYPE BRANCH_STATUS AS ENUM ('normally operational', 'under maintenance', 'out-of-business');

CREATE TABLE IF NOT EXISTS "Branch"
(
    "branchId"            UUID PRIMARY KEY                                  DEFAULT "uuid_generate_v4"(),
    "name"                VARCHAR(50) UNIQUE                       NOT NULL,
    "provinceId"          INT REFERENCES "Province" ("provinceId") NOT NULL,
    "fullAddress"         TEXT                                     NOT NULL,
    "coordinateLatitude"  FLOAT                                    NOT NULL,
    "coordinateLongitude" FLOAT                                    NOT NULL,
    "email"               CITEXT                                   NOT NULL UNIQUE,
    "establishingDate"    DATE                                     NOT NULL DEFAULT now(),
    "status"              "branch_status"                          NOT NULL DEFAULT 'under maintenance'
);

CREATE TABLE IF NOT EXISTS "BranchTelephone"
(
    "branchId"    UUID PRIMARY KEY
        REFERENCES "Branch" ("branchId") ON DELETE CASCADE,
    "telephoneNo" VARCHAR(15) NOT NULL UNIQUE
);

CREATE TYPE DAY_OF_WEEK AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

CREATE TABLE IF NOT EXISTS "BranchOpenTime"
(
    "branchId"    UUID
        REFERENCES "Branch" ("branchId") ON DELETE CASCADE,
    "dayOfWeek"   DAY_OF_WEEK NOT NULL,
    "timeOpening" TIME        NOT NULL,
    "timeClosing" TIME        NOT NULL,
    CHECK ( "timeClosing" > "timeOpening"),
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
    "isSupportFingerprintBiometric" BOOL NOT NULL DEFAULT FALSE,
    PRIMARY KEY ("computerMachineId"),
    UNIQUE ("serialNumber"),
    UNIQUE ("macAddress"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId")
) INHERITS ("ComputerMachine");

CREATE TABLE IF NOT EXISTS "CashierMachine"
(
    PRIMARY KEY ("computerMachineId"),
    UNIQUE ("serialNumber"),
    UNIQUE ("macAddress"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId")
) INHERITS ("ComputerMachine");

CREATE TABLE IF NOT EXISTS "SaladBar"
(
    "saladBarId" UUID PRIMARY KEY DEFAULT "uuid_generate_v4"(),
    "branchId"   UUID
        REFERENCES "Branch" ("branchId") ON DELETE CASCADE
);

/**
  Employee
 */
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
    "birthdate"        DATE                                                    NOT NULL CHECK ( "birthdate" < "joinDate" ),
    "wage"             DECIMAL(12, 2)                                          NOT NULL CHECK ( "wage" > 300 ),
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

/**
  "Waiter" related relations
 */
CREATE TABLE IF NOT EXISTS "WorldLanguageRef"
(
    "worldLanguageRefId" SERIAL PRIMARY KEY,
    "name"               VARCHAR(30) UNIQUE NOT NULL,
    "alias"              VARCHAR(30) UNIQUE
);

CREATE TABLE IF NOT EXISTS "Waiter"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

CREATE TABLE IF NOT EXISTS "WaiterLanguageFluency"
(
    "employeeId"         UUID REFERENCES "Employee" ("employeeId"),
    "worldLanguageRefId" INT REFERENCES "WorldLanguageRef" ("worldLanguageRefId")
);

/**
  Kitchen Porter
 */
CREATE TABLE IF NOT EXISTS "KitchenPorter"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

/**
  Chef
 */
CREATE TABLE IF NOT EXISTS "CookingRoleRef"
(
    "cookingRoleRefId" SERIAL PRIMARY KEY,
    "name"             VARCHAR(30) NOT NULL UNIQUE,
    "description"      TEXT        NOT NULL
);

CREATE TABLE IF NOT EXISTS "Chef"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

CREATE TYPE PRIORITY AS ENUM ('high', 'medium', 'role');

CREATE TABLE IF NOT EXISTS "ChefCookingRole"
(
    "employeeId"       UUID REFERENCES "Chef" ("employeeId"),
    "cookingRoleRefId" INT REFERENCES "CookingRoleRef" ("cookingRoleRefId"),
    "priority"         PRIORITY NOT NULL DEFAULT 'medium'
);

/**
  Cashier
 */
CREATE TABLE IF NOT EXISTS "Cashier"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

/**
  Kitchen Manager
 */
CREATE TABLE IF NOT EXISTS "KitchenManager"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

/**
  Delivery Man
 */
CREATE TABLE IF NOT EXISTS "DeliveryMan"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

/**
  Branch Manager
 */
CREATE TABLE IF NOT EXISTS "BranchManager"
(
    PRIMARY KEY ("employeeId"),
    FOREIGN KEY ("educationLevelId")
        REFERENCES "EducationLevelRef" ("educationLevelId"),
    FOREIGN KEY ("provinceId")
        REFERENCES "Province" ("provinceId"),
    FOREIGN KEY ("branchId")
        REFERENCES "Branch" ("branchId"),
    UNIQUE ("citizenId"),
    UNIQUE ("email")
) INHERITS ("Employee");

CREATE TABLE IF NOT EXISTS "EmployeeWagePayment"
(
    "employeeId"        UUID           NOT NULL REFERENCES "Employee" ("employeeId"),
    "wagePaymentAmount" DECIMAL(12, 2) NOT NULL,
    "wageBonusAmount"   DECIMAL(12, 2) NOT NULL,
    "timestamp"         TIMESTAMP      NOT NULL DEFAULT now(),
    "branchManagerId"   UUID           NOT NULL REFERENCES "BranchManager" ("employeeId"),
    PRIMARY KEY ("employeeId", "branchManagerId", "timestamp")
);

/**
  Member Customer
 */
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
    "memberCustomerRef"     UUID      NOT NULL REFERENCES "MemberCustomer" ("memberCustomerId"),
    "timestamp"             TIMESTAMP NOT NULL DEFAULT now(),
    "pointSpent"            INT       NOT NULL,
    PRIMARY KEY ("redeemableRewardRefId", "memberCustomerRef", "timestamp")
);

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

/**
  Billing
 */
CREATE TABLE IF NOT EXISTS "Billing"
(
    "billingId"                UUID PRIMARY KEY   DEFAULT "uuid_generate_v4"(),
    "taxInvoiceId"             VARCHAR(20) UNIQUE,
    "timeCreated"              TIMESTAMP NOT NULL DEFAULT now(),
    "timePaid"                 TIMESTAMP,
    "timeCanceled"             TIMESTAMP,
    "involvedMemberCustomerId" UUID REFERENCES "MemberCustomer" ("memberCustomerId"),
    "pointReceived"            INT CHECK ( ("involvedMemberCustomerId" IS NOT NULL AND "pointReceived" IS NOT NULL) OR
                                           ("involvedMemberCustomerId" IS NULL AND "pointReceived" IS NULL) ),
    "pointExpirationTime"      INTERVAL CHECK ( ("pointReceived" IS NOT NULL AND "pointExpirationTime" IS NOT NULL) OR
                                                ("pointReceived" IS NULL AND "pointExpirationTime" IS NULL) )
);

CREATE TABLE IF NOT EXISTS "BillingOnSite"
(
    PRIMARY KEY ("billingId"),
    FOREIGN KEY ("involvedMemberCustomerId")
        REFERENCES "MemberCustomer" ("memberCustomerId")
) INHERITS ("Billing");

CREATE TABLE IF NOT EXISTS "BillingDelivery"
(
    "deliveryManId" UUID NOT NULL REFERENCES "DeliveryMan" ("employeeId"),
    "timeUsed"      INTERVAL,
    "distanceKM"    FLOAT CHECK ( ("timeUsed" IS NULL AND "distanceKM" IS NULL) OR
                                  ("timeUsed" IS NOT NULL AND "distanceKM" IS NOT NULL) ),
    PRIMARY KEY ("billingId"),
    FOREIGN KEY ("involvedMemberCustomerId")
        REFERENCES "MemberCustomer" ("memberCustomerId")
) INHERITS ("Billing");

CREATE TABLE IF NOT EXISTS "CashierBillingHandling"
(
    "cashierId"        UUID REFERENCES "Cashier" ("employeeId"),
    "cashierMachineId" UUID REFERENCES "CashierMachine" ("computerMachineId"),
    "billingId"        UUID REFERENCES "BillingOnSite" ("billingId"),
    PRIMARY KEY ("cashierId", "cashierMachineId", "billingId")
);