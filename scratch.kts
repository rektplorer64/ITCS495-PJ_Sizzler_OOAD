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

    relationship set<Employee>          operatedBy                  inverse     Employee::worksAt;
    relationship SaladBar               offersSaladBar              inverse     SaladBar::offeredBy;
    relationship set<ComputerMachine>   deploysComputerMachine      inverse     ComputerMachine::deployedBy;
    relationship set<CustomerDelivery>  handlesCustomerDelivery     inverse     CustomerDelivery::handledBy;
    relationship set<MemberCustomer>    locatedNear                 inverse     MemberCustomer::livesNear;

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
    boolean loginToCashierSystem();
    boolean logoutFromCashierSystem();
};

class KitchenManager extends Employee(extent kitchenManagers){
    void summarizeInvolvedIngredientTx();
};

class DeliveryMan extends Employee(extent deliveryMen){
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

class CashierMachine extends ComputerMachine(extent cashierMachines){}

interface CustomerInstance{
    attribute   string          custInstanceId;
    void addOrder(in Order order) raises(OrderAlreadyExistedException, MalformedOrderException);
};

class CustomerPax : CustomerInstance (extent customerPaxes key custInstanceId){
    attribute   short           totalCustomers;

    relationship Table      uses        inverse     Table::isUsedBy;
    relationship set<Order> creates     inverse     Order::createdByOnSite;
};

class CustomerDelivery : CustomerInstance(extent customerDeliveries key custInstanceId){
    attribute   string          telephoneNo;
    attribute   string          fullAddress;
    attribute   string          province;

    relationship Branch     handledBy       inverse     Branch::handlesCustomerDelivery;
    relationship Order      creates         inverse     Order::createdByDelivery;
};

class Table{
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