class BranchOpenTime{
    attribute   enum DayOfWeek {
        'monday', 'tuesday', 'wednesday',
        'thursday', 'friday', 'saturday',
        'sunday'}                      dayOfWeek;
    attribute   time                   timeOpening;
    attribute   time                   timeClosing;
};

class Branch(extent branches key branchId){
    attribute   string                  branchId;
    attribute   string                  name;
    attribute   struct      Address {
        string      province,
        string      fullAddress,
        float       coordinateLatitude,
        float       coordinateLongitude
    }                                   address;
    attribute   list<string>            telephoneNumber;
    attribute   string                  email;
    attribute   date                    establishingDate;
    attribute   enum BranchStatus{
        'normally operational',
        'under maintenance',
        'out-of-business' }             establishingDate;
    attribute   set<BranchOpenTime>     openTime;
    attribute   set<Table>              tables;     // FIXME: Investigate whether this works.

    relationship set<Employee>                      operatedBy                  inverse     Employee::worksAt;
    relationship SaladBar                           offersSaladBar              inverse     SaladBar::offeredBy;
    relationship set<ComputerMachine>               deploysComputerMachine      inverse     ComputerMachine::deployedBy;
    relationship set<CustomerDelivery>              handlesCustomerDelivery     inverse     CustomerDelivery::handledBy;
    relationship set<MemberCustomer>                locatedNear                 inverse     MemberCustomer::livesNear;
    relationship set<InventoryInboundOrderItem>     manages                     inverse     InventoryInboundOrderItem::managedBy;
    relationship set<MenuRef>                       menuOffers                  inverse     MenuRef::menuOfferedBy;

    void updateStatus(in BranchStatus status);
    void printBranchSummary();
};

class SaladBar(extent saladBars key saladBarId){
    attribute   string          saladBarId;

    relationship Branch offeredBy inverse Branch::offersSaladBar

    void summarizeIngredientUsage()
};

class ComputerMachine(extent computerMachines key computerMachineId){
    attribute   string          computerMachineId;
    attribute   string          macAddress;
    attribute   string          serialNumber;
    attribute   timestamp       deploymentTimestamp;

    relationship Branch deployedBy inverse Branch::deploysComputerMachine;
};

class TimeAttendanceMachine extends ComputerMachine(extent timeAttendanceMachines){
    attribute       boolean     isSupportFingerprintBiometric;

    relationship    set<ClockInOut>     relatesTo   inverse     ClockInOut::performedAt;
};

class Employee(extent employees key employeeId){
    attribute   string              employeeId;
    attribute   string              firstname;
    attribute   string              surname;
    attribute   string              nickname;
    attribute   string              email;
    attribute   set<string>         telephoneNo;
    attribute   enum EducationLevel {
        'Vocational Certificate',
        'High Vocational Certificate',
        'High School',
        'Primary School'}           educationLevel;
    attribute   struct      Address {
        string      province,
        string      fullAddress}    address;
    attribute   enum Gender {
        'male', 'female'}           gender;
    attribute   string              citizenId;
    attribute   date                joinDate;
    attribute   data                birthdate;
    attribute   float               wage;
    attribute   set<WorkTime>       workTimes;

    relationship    Branch                       worksAt        inverse     Branch::operatedBy;
    relationship    set<ClockInOut>              performs       inverse     ClockInOut::performedBy;
    relationship    set<EmployeeWagePayment>     getsPaidVia    inverse     EmployeeWagePayment::paysTo;

    float summarizeWageToPay();
    void summarizeWorkAttendance();
    boolean assignRole(in string role) raises(InvalidRoleArgumentException);
    boolean unassignRole(in string role) raises(InvalidRoleArgumentException, NoRoleToUnassignException);
    boolean checkInWork();
    boolean checkOutWork();
};

class Waiter extends Employee(extent waiters){
    attribute   set<string>     languageFluency;

    relationship    Order       handles     inverse     Order::handledBy;
};

class KitchenPorter extends Employee(extent kitchenPorters){};

class ChefCookingRole{
    attribute   string      name;
    attribute   string      description;
    attribute   enum Priority {'low',
        'medium', 'high'}   priority;
};

class Chef extends Employee(extent chefs){
    attribute   set<ChefCookingRole>    cookingRole;
};

class Cashier extends Employee(extent cashiers){

    relationship    set<CashierBillingHandling>     participates    inverse     CashierBillingHandling::participatedBy;

    boolean loginToCashierSystem();
    boolean logoutFromCashierSystem();
};

class KitchenManager extends Employee(extent kitchenManagers){
    relationship    set<InventoryInboundOrder>      manages     inverse     InventoryInboundOrder::managedBy;

    void summarizeInvolvedIngredientTx();
};

class DeliveryMan extends Employee(extent deliveryMen){
    attribute   string      timeUsed;
    attribute   float       distanceKM;

    relationship    set<BillingDelivery>    deliverItemsFor     inverse     BillingDelivery::deliveredBy;

    boolean acceptDeliveryJob(in BillingDelivery billingDelivery)
};

class EmployeeWagePayment(extent employeeWagePayments){
    attribute   float       wagePaymentAmount
    attribute   timestamp   timestamp;

    relationship    BranchManager   madeBy  inverse     BranchManager::makes;
    relationship    Employee        paysTo  inverse     Employee::getsPaidVia;
};

class BranchManager extends Employee(extent branchManagers){
    relationship   set<EmployeeWagePayment>     makes   inverse     EmployeeWagePayment::madeBy;
};

class ClockInOut(extent clockInOuts key clockInTimestamp){
    attribute       timestamp       clockInTimestamp;
    attribute       timestamp       clockOutTimestamp;

    relationship TimeAttendanceMachine performedAt      inverse     TimeAttendanceMachine::relatesTo;
    relationship Employee              performedBy      inverse     Employee::performs;
    relationship WorkTime              involvedWith     inverse     WorkTime::involves;
};

class CashierMachine extends ComputerMachine(extent cashierMachines){
    relationship    set<CashierBillingHandling>     involvedIn  inverse     CashierBillingHandling::involves;
};

interface CustomerInstance{
    attribute   string          custInstanceId;
    void addOrder(in Order order) raises(OrderAlreadyExistedException, MalformedOrderException);
};

class CustomerPax : CustomerInstance (extent customerPaxes key custInstanceId){
    attribute   short           totalCustomers;

    relationship Table              uses        inverse     Table::isUsedBy;
    relationship set<Order>         creates     inverse     Order::createdByOnSite;
    relationship BillingOnSite      owns        inverse     BillingOnSite::ownedBy;
};

class CustomerDelivery : CustomerInstance(extent customerDeliveries key custInstanceId){
    attribute   string          telephoneNo;
    attribute   string          fullAddress;
    attribute   string          province;

    relationship Branch             handledBy       inverse     Branch::handlesCustomerDelivery;
    relationship Order              creates         inverse     Order::createdByDelivery;
    relationship BillingDelivery    responsibleFor  inverse     BillingDelivery::responsibleBy;
};

class Table(key tableId){
    attribute   short          tableId;

    relationship set<CustomerPax> isUsedBy inverse CustomerPax::uses;
};

class Order (extent orders key orderId){
    attribute   string          orderId;
    attribute   timestamp       timeCreated;
    attribute   string          note;

    relationship CustomerPax        createdByOnSite     inverse     CustomerPax::creates;
    relationship CustomerDelivery   createdByDelivery   inverse     CustomerDelivery::creates;
    relationship Waiter             handledBy           inverse     Waiter::handlesOrder;
    relationship set<OrderItem>     includes            inverse     OrderItem::includedIn;

    void summarizeOrder();
    void addFoodOrder(in OrderItem orderItem);
};

class WorkTime (extent workTimes key workTimeId){
    attribute   int             workTimeId;
    attribute   enum DayOfWeek {
        'monday', 'tuesday', 'wednesday',
        'thursday', 'friday', 'saturday',
        'sunday'}               dayOfWeek;
    attribute   time            timeStart;
    attribute   time            timeEnd;
    attribute   boolean         isPartTime;

    relationship    set<ClockInOut>  involves    inverse     ClockInOut::involvedWith;

};

class MemberCustomer(extent memberCustomers key memberCustomerId){
    attribute   string          memberCustomerId;
    attribute   string          firstname;
    attribute   string          surname;
    attribute   string          telephoneNo;
    attribute   date            birthdate;
    attribute   string          hashedPwd;
    attribute   string          salt;
    attribute   string          email;

    relationship    Branch                              livesNear   inverse     Branch::locatedNear;
    relationship    set<CustomerRewardRedemption>       creates     inverse     CustomerRewardRedemption::createdBy;

    boolean updatePassword(in string password) raises(MalformedPasswordException,
                        TooShortPasswordException, TooLongPasswordException,
                        WeakPasswordException);
};

class CustomerRewardRedemption(extent customerRewardRedemptions){
    attribute   timestamp       timestamp;
    attribute   short           pointSpent;

    relationship    MemberCustomer          createdBy       inverse     MemberCustomer::creates;
    relationship    RedeemableRewardRef     isBasedOn       inverse     RedeemableRewardRef::leadsTo;
};

class MemberLevelRef(extent memberLevelRefs key memberLevelRefId){
    attribute   string          memberLevelRefId;
    attribute   string          name;
    attribute   string          description;
    attribute   short           pointThreshold;

    relationship    set<RedeemableRewardRef>    offers      inverse     RedeemableRewardRef::offeredBy;
}

class RedeemableRewardRef(extent redeemableRewards key redeemableRewardRefId){
    attribute   string          redeemableRewardRefId;
    attribute   string          name;
    attribute   string          description;
    attribute   short           basePointRequired;
    attribute   boolean         isInUse;

    relationship    set<CustomerRewardRedemption>   leadsTo     inverse     CustomerRewardRedemption::isBasedOn;
    relationship    set<MemberLevelRef>             offeredBy   inverse     MemberLevelRef::offers;

    void summarizeUsage();
};

class Billing(extent billings key billingId){
    attribute   string          billingId;
    attribute   string          taxInvoiceId;
    attribute   timestamp       timeCreated;
    attribute   timestamp       timePaid;
    attribute   timestamp       timeCanceled;
    attribute   short           pointReceived;
    attribute   timestamp       pointExpirationTime;
    attribute   set<Order>      orders;

    relationship    PaymentTransaction     involves      inverse     PaymentTransaction::involvedBy;

    void summarize();
    boolean cancelBilling() raises(CannotCancelBillException);
    void verifyRelatedTransactions() raises(NoVerifiableTransactionException);
    boolean addPaymentTransaction(in PaymentTransaction tx) raises(InvalidTransactionException);
    boolean bindToMemberCustomer(in MemberCustomer memberCustomer) raises(NoSuchMemberCustomerException);
};

class BillingOnSite extends Billing(extent billingOnSite){
    relationship    CashierBillingHandling   needs      inverse     CashierBillingHandling::needed;
    relationship    CustomerPax              ownedBy    inverse     CustomerPax::owns;
};

class BillingDelivery extends Billing(extent billingDelivery){
    relationship    DeliveryMan     deliveredBy     inverse     DeliveryMan::deliverItemsFor;
    relationship    CustomerPax     responsibleBy   inverse     CustomerPax::responsibleFor;
};

class CashierBillingHandling(extent cashierBillingHandlings){
    relationship    Cashier         participatedBy  inverse     Cashier::participates;
    relationship    CashierMachine  involves        inverse     CashierMachine::involvedIn;
    relationship    BillingOnSite   needed          inverse     BillingOnSite::needs;
};

class InventoryInboundOrder(extent inventoryInboundOrders key inboundOrderId){
    attribute       long            inboundOrderId;
    attribute       timestamp       timeCreated;
    attribute       timestamp       timeDelivered;
    attribute       timestamp       timeCanceled;
    attribute       string          note;
    attribute       string          deliverIn;

    relationship    KitchenManager  managedBy   inverse     KitchenManager::manages;

    void cancel();
    boolean markAsDelivered();
};

class InventoryInboundOrderItem(key inboundOrderItemId){
    attribute       string          inboundOrderItemId;
    attribute       timestamp       verificationTime;
    attribute       short           quantity;
    attribute       string          quantityUnit;
    attribute       short           pricePerUnit;

    relationship Branch                     managedBy       inverse     Branch::managesTable;
    relationship FoodItemIngredientRef      involves        inverse     FoodItemIngredientRef::involvedWith;
};

interface PaymentTransaction{
    attribute       string          paymentTransactionId;
    attribute       timestamp       timestamp;

    relationship    Billing     involvedBy      inverse     Billing::involves;

    void verifyValidity() raises(InvalidPaymentTransactionException);
};

class CashTransaction : PaymentTransaction(extent cashTransactions key paymentTransactionId){
    attribute       float           amount;
};

class CreditTransaction : PaymentTransaction(extent creditTransactions key paymentTransactionId){
    attribute       string          cardNumber;
    attribute       float           amount;
};

class GiftVoucherTransaction : PaymentTransaction(extent giftVoucherTransactions key paymentTransactionId){
    relationship    GiftVoucher     consequenceOf   inverse     GiftVoucher::leadsTo;
};

class GiftVoucherRef(extent giftVoucherRefs key giftVoucherRefId){
    attribute       long            giftVoucherRefId;
    attribute       string          name;
    attribute       string          description;
    attribute       timestamp       timeAdded;
    attribute       timestamp       timeCanceled;
    attribute       short           valueAmount;
    attribute       string          lifetime;

    relationship    set<GiftVoucher>     giftVoucherNo   inverse     GiftVoucher::refersTo;

    void summarizeOverVoucherLevelUsage()
    void cancelVoucherUsage()
};

class GiftVoucher(extent giftVouchers key giftVoucherId){
    attribute       long            giftVoucherNo;
    attribute       timestamp       timeIssued;

    relationship    GiftVoucherRef          refersTo    inverse GiftVoucherRef::referredBy;
    relationship    GiftVoucherTransaction  leadsTo     inverse GiftVoucherTransaction::consequenceOf;
};

class OrderItem(extent orderItems key orderItemId){
    attribute       long            orderItemId;
    attribute       short           quantity;
    attribute       timestamp       timeStarted;
    attribute       timestamp       timeServed;
    attribute       float           perUnitPrice;
    attribute       float           perUnitDiscount;
    attribute       float           perUnitTakeHomeFee;
    attribute       boolean         isRefunded;

    relationship    MenuRef                         refersTo     inverse MenuRef::referredBy;
    relationship    Order                           includedIn   inverse Order::includes;
    relationship    set<MenuServingCustomization>   tiedWith     inverse MenuServingCustomization::tiesTo;

    void markAsServed() raises(OrderItemAlreadyServedException, OutOfTimeWindowException);
    void markAsRefunded() raises(OrderItemAlreadyRefundedException, OutOfTimeWindowException);
    boolean customizeServing(in MenuServingCustomization customization) raises(IllegalMenuCustomizationException);
};

class SeasonRef(extent seasonRefs key seasonRefId){
    attribute       long            seasonRefId;
    attribute       string          name;
    attribute       date            dateStart;
    attribute       date            dateEnd;

    relationship    set<MenuRef>    dependedBy  inverse     MenuRef::dependsOnSeason;
};

class MenuAvailability(extent menuAvailability key menuAvailabilityId){
    attribute       long            menuAvailabilityId;
    attribute       enum DayOfWeek {
        'monday', 'tuesday', 'wednesday',
        'thursday', 'friday', 'saturday',
        'sunday'}                   dayOfWeek;
    attribute       time            timeRangeStart;
    attribute       time            timeRangeEnd;

    relationship MenuRef    dependedBy      inverse     MenuRef::dependsOnAvailability;
};

class MenuRef(extent menuRefs key menuRefId){
    attribute       long            menuRefId;
    attribute       string          nameEng;
    attribute       string          nameTha;
    attribute       string          descriptionEng;
    attribute       string          descriptionTha;
    attribute       date            dateAdded;
    attribute       boolean         isActive;

    relationship set<Branch>            menuOfferedBy               inverse     Branch::menuOffers;
    relationship set<OrderItem>         referredBy                  inverse     OrderItem::refersTo;
    relationship set<SeasonRef>         dependsOnSeason             inverse     SeasonRef::dependedBy;
    relationship set<MenuAvailability>  dependsOnAvailability       inverse     MenuAvailability::dependedBy;
    relationship set<MenuServingRef>    includes                    inverse     MenuServingRef::includedIn;

    void toggleIsActive();
    string calculatePopularity();
};

class ServingRef(extent servingRefs key servingRefId){
    attribute       long            servingRefId;
    attribute       string          nameEng;
    attribute       string          nameTha;
    attribute       string          descriptionEng;
    attribute       string          descriptionTha;
    attribute       enum Genre {
        'australia', 'asian', 'western'
    }                               genre;
    attribute       float           basePrice;
    attribute       date            dateAdded;
    attribute       boolean         hasFreeSaladBar;

    relationship    set<MenuServingRef>         tiedIn      inverse     MenuServingRef::tiesTo;
    relationship    set<ServingFoodItemRef>     involves    inverse     ServingFoodItemRef::involvedIn;
};

class MenuServingRef(extent menuServingRefs){
    attribute       float           realPrice;
    attribute       timestamp       pricingTimestamp;

    relationship    MenuRef         includedIn      inverse     MenuRef::includes;
    relationship    ServingRef      tiesTo          inverse     ServingRef::tiedIn;
};

class Food extends ServingRef{
    attribute       string          cookingDescription;
    attribute       enum FoodType {
        'steak', 'double steaks', 'burger', 'salad', 'rice', 'spaghetti', 'wrap', 'sandwich'
    }                               type;
    attribute       boolean         isForChildren;
};

class Appetizer extends Food{
};

class Beverage extends ServingRef{
    attribute       float           volumeOz;
    attribute       boolean         isRefillable;
};

class FoodItemRef(extent foodItemRefs key foodItemRefId){
    attribute       long            foodItemRefId;
    attribute       string          nameEng;
    attribute       string          nameTha;
    attribute       string          descriptionTha;
    attribute       string          descriptionEng;

    relationship    set<ServingFoodItemRef>         involvedIn      inverse     ServingFoodItemRef::involves;
    relationship    set<FoodItemIngredientRef>      consistsOf      inverse     FoodItemIngredientRef::consistedOf;
    relationship    set<MenuServingCustomization>   replacedBy      inverse     MenuServingCustomization::replacesWith;

    string inferConsumption(in set<Branch> branches) raises(IllegalArgumentException, NoSuchBranchException);
};

class ServingFoodItemRef(extent servingFoodItemRef){
    attribute       short           quantity;
    attribute       string          quantityUnit;
    attribute       boolean         isCustomizable;

    relationship    ServingRef                       involvedWith    inverse     ServingRef::involves;
    relationship    FoodItemRef                      involves        inverse     FoodItemRef::involvedIn;
    relationship    set<MenuServingCustomization>    relates         inverse     MenuServingCustomization::relatesTo;
};

class FoodItemIngredientRef(extent foodIngredientRefs){
    attribute       float           quantity;
    attribute       string          quantityUnit

    relationship    FoodItemRef             consistedOf      inverse        FoodItemRef::consistsOf;
    relationship    FoodIngredientRef       madeOf           inverse        FoodIngredientRef::make;

};

class FoodIngredientRef(extent foodIngredientRefs key foodIngredientRefId){
    attribute       long            foodIngredientRefId;
    attribute       string          nameEng;
    attribute       string          nameTha;
    attribute       string          description;
    attribute       enum Category{
        'meat', 'vegetable',
        'spice', 'sauce',
        'desert', 'beverage',
        'fruit'}                    category;

    relationship    set<FoodItemIngredientRef>          make            inverse     FoodItemIngredientRef::madeOf;
    relationship    set<InventoryInboundOrderItem>      involvedWith    inverse     InventoryInboundOrderItem::involves;

    string inferConsumption(in set<Branch> branches) raises(IllegalArgumentException, NoSuchBranchException);
};

class MenuServingCustomization(extent menuServingCustomizations){
    relationship    OrderItem                   tiesTo          inverse      OrderItem::tiedWith;
    relationship    ServingFoodItemRef          relatesTo       inverse      ServingFoodItemRef::relates;
    relationship    FoodItemRef                 replacesWith    inverse      FoodItemRef::replacedBy;
};