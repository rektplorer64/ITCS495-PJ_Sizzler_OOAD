CREATE OR REPLACE FUNCTION "calculateOrderItemPrice"(
    "perUnitPrice"       NUMERIC(12, 2),
    "perUnitTakeHomeFee" NUMERIC(12, 2),
    "perUnitDiscount"    NUMERIC(12, 2),
    "quantity"           INT
)
    RETURNS INTEGER IMMUTABLE AS
$body$
BEGIN
    RETURN sum(("perUnitPrice" + coalesce("perUnitTakeHomeFee", 0) - coalesce("perUnitDiscount", 0)) * "quantity");
END
$body$ LANGUAGE "plpgsql";


CREATE OR REPLACE FUNCTION "mapToDayOfWeekInt"(
    "dayOfWeek" DAY_OF_WEEK
)
    RETURNS INTEGER
    IMMUTABLE AS
$body$
BEGIN
    CASE "dayOfWeek"
        WHEN 'sunday'::DAY_OF_WEEK THEN RETURN 0;
        WHEN 'monday'::DAY_OF_WEEK THEN RETURN 1;
        WHEN 'tuesday'::DAY_OF_WEEK THEN RETURN 2;
        WHEN 'wednesday'::DAY_OF_WEEK THEN RETURN 3;
        WHEN 'thursday'::DAY_OF_WEEK THEN RETURN 4;
        WHEN 'friday'::DAY_OF_WEEK THEN RETURN 5;
        ELSE RETURN 6; END CASE;
END
$body$ LANGUAGE "plpgsql";