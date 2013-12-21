//
//  Copyright (c) 2013 Fish Hook LLC. All rights reserved.
//

#import "FHKMasterViewController.h"

@interface FHKMasterViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) NSManagedObject *classroomA;
@property (strong, nonatomic) NSManagedObject *classroomB;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *classroomAButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *classroomBButton;

@end

@implementation FHKMasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    NSManagedObject *classroomA = [NSEntityDescription insertNewObjectForEntityForName:@"Classroom" inManagedObjectContext:self.managedObjectContext];
    [classroomA setValue:@"Classroom A" forKey:@"name"];
    [self setClassroomA:classroomA];
    
    NSManagedObject *classroomB = [NSEntityDescription insertNewObjectForEntityForName:@"Classroom" inManagedObjectContext:self.managedObjectContext];
    [classroomB setValue:@"Classroom B" forKey:@"name"];
    [self setClassroomB:classroomB];
}

- (IBAction)insertNewObject:(id)sender
{
    static int count = 0;
    
    NSManagedObject *newChild = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:self.managedObjectContext];
    [newChild setValue:[NSString stringWithFormat:@"Child #%i", ++count] forKey:@"name"];
    [[newChild mutableSetValueForKey:@"classrooms"] addObject:self.classroomA];
    [[newChild mutableSetValueForKey:@"classrooms"] addObject:self.classroomB];
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (IBAction)deleteClassroom:(id)sender
{
    NSManagedObject *objectToDelete;
    
    if (sender == self.classroomAButton) {
        objectToDelete = self.classroomA;
    }
    else if (sender == self.classroomBButton) {
        objectToDelete = self.classroomB;
    }
    
    NSError *deleteValidationError;
    if (![objectToDelete validateForDelete:&deleteValidationError]) {
        NSLog(@"%@", deleteValidationError);
    }
    
    [self.managedObjectContext deleteObject:objectToDelete];

    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        NSManagedObject *deleteMe = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSError *deleteValidationError = nil;
        if (![deleteMe validateForDelete:&deleteValidationError]) {
            NSLog(@"%@", deleteValidationError);
        }
        
        [self.managedObjectContext deleteObject:deleteMe];
        
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:self.managedObjectContext
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];
    frc.delegate = self;
    self.fetchedResultsController = frc;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [object valueForKey:@"name"];
}

@end
