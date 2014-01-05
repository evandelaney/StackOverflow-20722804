//
//  Copyright (c) 2014 Fish Hook LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>

@interface StackOverflow_20722804_Tests : XCTestCase

// Managed Object Model: Project <<---->> Employee <<----> Department

@property (strong, nonatomic) NSEntityDescription *project;
@property (strong, nonatomic) NSEntityDescription *employee;
@property (strong, nonatomic) NSEntityDescription *department;

@property (strong, nonatomic) NSRelationshipDescription *projectToManyEmployee;
@property (strong, nonatomic) NSRelationshipDescription *employeeToManyProject;
@property (strong, nonatomic) NSRelationshipDescription *employeeToOneDepartment;
@property (strong, nonatomic) NSRelationshipDescription *departmentToManyEmployee;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

//----------------------------------------------------------------------------//

static NSString * const kEntityNameEmployee   = @"Employee";
static NSString * const kEntityNameDepartment = @"Department";
static NSString * const kEntityNameProject    = @"Project";

static NSString * const kNameAttribute = @"name";
static NSString * const kEmployeesRelationship = @"employees";
static NSString * const kProjectsRelationship = @"projects";
static NSString * const kDepartmentRelaitonship = @"department";

//----------------------------------------------------------------------------//

@implementation StackOverflow_20722804_Tests

- (void)setUp
{
    [super setUp];
    
    _project = [[NSEntityDescription alloc] init];
    [_project setName:kEntityNameProject];
    
    _employee = [[NSEntityDescription alloc] init];
    [_employee setName:kEntityNameEmployee];
    
    _department = [[NSEntityDescription alloc] init];
    [_department setName:kEntityNameDepartment];
    
//    -[NSPropertyDescription isTransient];    // Default: NO
//    -[NSPropertyDescription isOptional];     // Default: YES
    
    NSAttributeDescription *nameAttribute = [[NSAttributeDescription alloc] init];
    [nameAttribute setName:kNameAttribute];
    [nameAttribute setAttributeType:NSStringAttributeType];
    [nameAttribute setAttributeValueClassName:NSStringFromClass([NSString class])];
    
//    -[NSRelationshipDescription deleteRule]; // Default: NSNullifyDeleteRule
//    -[NSRelationshipDescription minCount];   // Default: 0
//    -[NSRelationshipDescription maxCount];   // Default: 0
    
    _projectToManyEmployee = [[NSRelationshipDescription alloc] init];
    [_projectToManyEmployee setName:kEmployeesRelationship];
    [_projectToManyEmployee setDestinationEntity:_employee];
    
    _employeeToManyProject = [[NSRelationshipDescription alloc] init];
    [_employeeToManyProject setName:kProjectsRelationship];
    [_employeeToManyProject setDestinationEntity:_project];
    
    _employeeToOneDepartment = [[NSRelationshipDescription alloc] init];
    [_employeeToOneDepartment setName:kDepartmentRelaitonship];
    [_employeeToOneDepartment setMaxCount:1];
    [_employeeToOneDepartment setDestinationEntity:_department];
    
    _departmentToManyEmployee = [[NSRelationshipDescription alloc] init];
    [_departmentToManyEmployee setName:kEmployeesRelationship];
    [_departmentToManyEmployee setDestinationEntity:_employee];
    
    [_projectToManyEmployee setInverseRelationship:_employeeToManyProject];
    [_employeeToManyProject setInverseRelationship:_projectToManyEmployee];
    [_employeeToOneDepartment setInverseRelationship:_departmentToManyEmployee];
    [_departmentToManyEmployee setInverseRelationship:_employeeToOneDepartment];
    
    [_project setProperties:@[ [nameAttribute copy], _projectToManyEmployee ]];
    [_employee setProperties:@[ [nameAttribute copy], _employeeToManyProject, _employeeToOneDepartment ]];
    [_department setProperties:@[ [nameAttribute copy], _departmentToManyEmployee ]];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] init];
    [_managedObjectModel setEntities:@[ _project, _employee, _department ]];
}

- (void)tearDown
{
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    
    _project = nil;
    _employee = nil;
    _department = nil;
    
    _projectToManyEmployee = nil;
    _employeeToManyProject = nil;
    _employeeToOneDepartment = nil;
    _departmentToManyEmployee = nil;
    
    [super tearDown];
}

#pragma mark - Lazy Loaded Managed Object Context

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator:psc];
        
        [self setManagedObjectContext:moc];
    }
    
    return _managedObjectContext;
}

#pragma mark - Unit Tests

- (void)testRelationshipDescriptions
{
    // To-Many
    XCTAssertTrue([self.projectToManyEmployee isToMany]);
    XCTAssertTrue([self.employeeToManyProject isToMany]);
    XCTAssertTrue([self.departmentToManyEmployee isToMany]);
    
    // To-One
    XCTAssertFalse([self.employeeToOneDepartment isToMany]);
}

#pragma mark - Simple Object Graphs -

#pragma mark Employee to-one Department

- (NSManagedObject *)setupEmployee1
{
    NSError *validationError = nil;
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameEmployee inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(employee);
    XCTAssertTrue([employee validateForDelete:&validationError], @"%@", validationError);
    
    NSManagedObject *department = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameDepartment inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(department);
    
    [employee setValue:department forKey:kDepartmentRelaitonship];
    XCTAssertTrue([[department valueForKey:kEmployeesRelationship] containsObject:employee]);
    XCTAssertEqualObjects([employee valueForKey:kDepartmentRelaitonship], department);

    return employee;
}

- (void)testEmployeeToOneDepartmentNullifyDelete
{
    [self.employeeToOneDepartment setDeleteRule:NSNullifyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *employee = [self setupEmployee1];
    
#warning Expected Behavior: Passes
    XCTAssertTrue([employee validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:employee];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testEmployeeToOneDepartmentCascadeDelete
{
    [self.employeeToOneDepartment setDeleteRule:NSCascadeDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *employee = [self setupEmployee1];
    
#warning Expected Behavior: Passes
    XCTAssertTrue([employee validateForDelete:&validationError]);

    [self.managedObjectContext deleteObject:employee];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testEmployeeToOneDepartmentDenyDelete
{
    [self.employeeToOneDepartment setDeleteRule:NSDenyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *employee = [self setupEmployee1];
    
    XCTAssertFalse([employee validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:employee];
    XCTAssertFalse([self.managedObjectContext save:NULL]);
}

#pragma mark Department to-many Employee

- (NSManagedObject *)setupDepartment
{
    NSError *validationError = nil;
    NSManagedObject *employee1 = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameEmployee inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(employee1);
    NSManagedObject *employee2 = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameEmployee inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(employee2);
    
    NSManagedObject *department = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameDepartment inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(department);
    XCTAssertTrue([department validateForDelete:&validationError]);
    
    [[department mutableSetValueForKey:kEmployeesRelationship] addObjectsFromArray:@[ employee1 , employee2 ]];
    XCTAssertTrue([[department valueForKey:kEmployeesRelationship] containsObject:employee1]);
    XCTAssertTrue([[department valueForKey:kEmployeesRelationship] containsObject:employee2]);
    XCTAssertEqualObjects([employee1 valueForKey:kDepartmentRelaitonship], department);
    XCTAssertEqualObjects([employee2 valueForKey:kDepartmentRelaitonship], department);

    return department;
}

- (void)testDepartmentToManyEmployeeNullifyDelete
{
    [self.departmentToManyEmployee setDeleteRule:NSNullifyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *department = [self setupDepartment];
    
#warning Expected Behavior: Passes
    XCTAssertTrue([department validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:department];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testDepartmentToManyEmployeeCascadeDelete
{
    [self.departmentToManyEmployee setDeleteRule:NSCascadeDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *department = [self setupDepartment];
    
#warning Expected Behavior: Passes
    XCTAssertTrue([department validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:department];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testDepartmentToManyEmployeeDenyDelete
{
    [self.departmentToManyEmployee setDeleteRule:NSDenyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *department = [self setupDepartment];
    
    XCTAssertFalse([department validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:department];
    XCTAssertFalse([self.managedObjectContext save:NULL]);
}

#pragma mark Employee to-many Project

- (NSManagedObject *)setupEmployee2
{
    NSError *validationError = nil;
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameEmployee inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(employee);
    XCTAssertTrue([employee validateForDelete:&validationError], @"%@", validationError);
    
    NSManagedObject *project1 = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameProject inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(project1);
    NSManagedObject *project2 = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameProject inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(project2);
    
    [[employee mutableSetValueForKey:kProjectsRelationship] addObjectsFromArray:@[ project1, project2 ]];
    XCTAssertTrue([[employee valueForKey:kProjectsRelationship] containsObject:project1]);
    XCTAssertTrue([[employee valueForKey:kProjectsRelationship] containsObject:project2]);
    
    return employee;
}

- (void)testEmployeeToManyProjectNullifyDelete
{
    [self.employeeToManyProject setDeleteRule:NSNullifyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *employee = [self setupEmployee2];
    
#warning Expected Behavior: Passes
    XCTAssertTrue([employee validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:employee];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testEmployeeToManyProjectCascadeDelete
{
    [self.employeeToManyProject setDeleteRule:NSCascadeDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *employee = [self setupEmployee2];
    
#warning Exepcted Behavior: Passes
    XCTAssertTrue([employee validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:employee];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testEmployeeToManyProjectDenyDelete
{
    [self.employeeToManyProject setDeleteRule:NSDenyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *employee = [self setupEmployee2];
    
    XCTAssertFalse([employee validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:employee];
    XCTAssertFalse([self.managedObjectContext save:NULL]);
}

#pragma mark Project to-many Employee

- (NSManagedObject *)setupProject
{
    NSError *validationError = nil;
    NSManagedObject *project = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameProject inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(project);
    XCTAssertTrue([project validateForDelete:&validationError], @"%@", validationError);
    
    NSManagedObject *employee1 = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameEmployee inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(employee1);
    NSManagedObject *employee2 = [NSEntityDescription insertNewObjectForEntityForName:kEntityNameEmployee inManagedObjectContext:self.managedObjectContext];
    XCTAssertNotNil(employee2);
    
    [[project mutableSetValueForKey:kEmployeesRelationship] addObjectsFromArray:@[ employee1, employee2 ]];
    XCTAssertTrue([[project valueForKey:kEmployeesRelationship] containsObject:employee1]);
    XCTAssertTrue([[project valueForKey:kEmployeesRelationship] containsObject:employee2]);
    
    return project;
}

- (void)testProjectToManyEmployeeNullifyDelete
{
    [self.projectToManyEmployee setDeleteRule:NSNullifyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *project = [self setupProject];
    
#warning Exepcted Behavior: Passes
    XCTAssertTrue([project validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:project];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testProjectToManyEmployeeCascadeDelete
{
    [self.projectToManyEmployee setDeleteRule:NSCascadeDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *project = [self setupProject];
    
#warning Exepcted Behavior: Passes
    XCTAssertTrue([project validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:project];
    XCTAssertTrue([self.managedObjectContext save:NULL]);
}

- (void)testProjectToManyEmployeeDenyDelete
{
    [self.projectToManyEmployee setDeleteRule:NSDenyDeleteRule];
    
    NSError *validationError = nil;
    NSManagedObject *project = [self setupProject];
    
    XCTAssertFalse([project validateForDelete:&validationError]);
    
    [self.managedObjectContext deleteObject:project];
    XCTAssertFalse([self.managedObjectContext save:NULL]);
}

@end
