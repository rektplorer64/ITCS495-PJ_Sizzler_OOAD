CREATE OR REPLACE FUNCTION "calculateOrderItemPrice"(
    "perUnitPrice"       NUMERIC(12, 2),
    "perUnitTakeHomeFee" NUMERIC(12, 2),
    "perUnitDiscount"    NUMERIC(12, 2),
    "quantity"           INT
)
    RETURNS INTEGER AS
$body$
BEGIN
    RETURN sum(("perUnitPrice" + coalesce("perUnitTakeHomeFee", 0) - coalesce("perUnitDiscount", 0)) * "quantity");
END
$body$ LANGUAGE "plpgsql";