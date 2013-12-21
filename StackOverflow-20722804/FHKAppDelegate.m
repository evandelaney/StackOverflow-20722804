//
//  Copyright (c) 2013 Fish Hook LLC. All rights reserved.
//

#import "FHKAppDelegate.h"

#import "FHKMasterViewController.h"

@interface FHKAppDelegate ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation FHKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    FHKMasterViewController *controller = (FHKMasterViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;
    
    return YES;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
    
        NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:nil];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        
        NSError *persistentStoreError = nil;
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TestApp.sqlite"];
        NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:nil
                                                          error:&persistentStoreError];
        if (!ps) {
            NSLog(@"%@", persistentStoreError);
            abort();
        }
        
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator:psc];
        
        [self setManagedObjectContext:moc];
    }
    return _managedObjectContext;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
