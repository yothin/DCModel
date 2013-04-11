///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCModel.m
//
//  Created by Dalton Cherry on 4/11/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCModel.h"
#import "GPHTTPRequest.h"
#import <CoreData/CoreData.h>
#import <objc/runtime.h>

@implementation DCModel

static NSManagedObjectContext* objectCtx;
static NSManagedObjectModel* managedObjectModel;
static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSOperationQueue* diskQueue;
static NSString* const DBName = @"dcmodel.sqlite";

typedef void (^DiskCallBack)(void);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//recommend async methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)get:(NSString*)url finished:(DCModelBlock)callback
{
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)getAll:(NSString*)url finished:(DCModelBlock)callback
{
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)all:(NSArray*)sortDescriptors finished:(DCModelBlock)callback
{
    [self find:nil sort:sortDescriptors finished:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)all:(DCModelBlock)callback
{
    [self find:nil sort:nil finished:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)find:(NSPredicate*)predicate sort:(NSArray*)sortDescriptors finished:(DCModelBlock)callback
{
    [self addDiskOperation:^{
        NSArray* items = [self find:predicate sort:sortDescriptors];
        callback(items);
    }];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)saveObjects:(NSArray*)objects
{
    //implement me!!!
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//unrecommend sync methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)get:(NSString*)url
{
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)getAll:(NSString*)url
{
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)all
{
    return [self find:nil sort:nil];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)allSorted:(NSArray*)sortDescriptors
{
    return [self find:nil sort:sortDescriptors];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)find:(NSPredicate*)predicate sort:(NSArray*)sortDescriptors
{
    NSString* name = [self getClassName:[self class]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:[DCModel objectCtx]];
    // Setup the fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    [request setSortDescriptors:sortDescriptors];
    request.predicate = predicate;
    
    NSArray *managedItems = [[DCModel objectCtx] executeFetchRequest:request error:nil];
    
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//public methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)clearDiskStorage
{
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//local public methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)fetchNetworkContent:(NSString*)url
{
    @autoreleasepool {
        GPHTTPRequest *request = [GPHTTPRequest requestWithString:url];
        [request setCacheTimeout:5];
        [request setCacheModel:GPHTTPCacheCustomTime];
        [request startSync];
        //do finish logic here.
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//core data stuff
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSManagedObjectContext*)objectCtx
{
    if (objectCtx)
        return objectCtx;
    
    NSPersistentStoreCoordinator *coordinator = [DCModel persistentStoreCoordinator];
    if (coordinator)
    {
        objectCtx = [[NSManagedObjectContext alloc] init];
        [objectCtx setPersistentStoreCoordinator:coordinator];
    }
    return objectCtx;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
        return managedObjectModel;
    /*if(self.migrationModelName)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:self.migrationModelName ofType:@"momd"];
        NSURL *momURL = [NSURL fileURLWithPath:path];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    }
    else
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];*/
    return managedObjectModel;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    
    NSURL *storeUrl = [NSURL fileURLWithPath: [[DCModel applicationDocumentsDirectory] stringByAppendingPathComponent:DBName]];
    
    NSDictionary *options = nil;
    /*if(self.migrationModelName)
    {
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                   [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    }*/
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[DCModel managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error])
    {
        NSLog(@"error: %@ userInfo: %@",error,[error userInfo]);
        static BOOL didReload;
        if(!didReload)
        {
            NSURL *storeUrl = [NSURL fileURLWithPath: [[DCModel applicationDocumentsDirectory] stringByAppendingPathComponent:DBName]];
            [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:nil];
            persistentStoreCoordinator = nil;
            managedObjectModel = nil;
            [DCModel persistentStoreCoordinator];
            didReload = YES;
        }
    }
    return persistentStoreCoordinator;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)addDiskOperation:(DiskCallBack)callback
{
    if(!diskQueue)
    {
        diskQueue = [[NSOperationQueue alloc] init];
        diskQueue.maxConcurrentOperationCount = 1;
    }
    [diskQueue addOperationWithBlock:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)getClassName:(Class)objectClass
{
    const char* className = class_getName(objectClass);
    NSString* identifier = [[NSString alloc] initWithBytesNoCopy:(char*)className
                                                           length:strlen(className)
                                                         encoding:NSASCIIStringEncoding freeWhenDone:NO];
    return identifier;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end
