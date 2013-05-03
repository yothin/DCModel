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
#import <objc/runtime.h>

@implementation NSManagedObject (ActiveRecord)

static NSManagedObjectContext* objectCtx;
static NSManagedObjectModel* managedObjectModel;
static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSOperationQueue* diskQueue;
static NSString* const DBName = @"dcmodel.sqlite";

typedef void (^DiskCallBack)(void);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)newObject
{
    return [self newObject:nil];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)newObject:(NSDictionary*)dict
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self objectCtx]];
    id managedObject = [[[self class] alloc] initWithEntity:entity insertIntoManagedObjectContext:nil]; //NSManagedObject
    //id managedObject = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:nil];
    for(NSString* key in dict)
    {
        if([managedObject respondsToSelector:NSSelectorFromString(key)])
            [managedObject setValue:[dict objectForKey:key] forKey:key];
    }
    return managedObject;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)destroy
{
    [NSManagedObject destroyObject:self];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)save
{
    [NSManagedObject saveObject:self];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)isDuplicate:(Class)class
{
    BOOL isDup = NO;
    NSString* key = [class primaryKey];
    if(key)
    {
        NSArray* items = [class where:[NSString stringWithFormat:@"%@ == '%@'",key,[self valueForKey:key]] sort:nil limit:1];
        if(items.count > 0)
            isDup = YES;
    }
    return isDup;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)primaryKey
{
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//recommend async methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)get:(NSString*)url finished:(DCModelBlock)callback
{
    dispatch_async(dispatch_get_global_queue(0, 0),^ {
        callback([self get:url]);
    });
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)getAll:(NSString*)url finished:(DCModelBlock)callback
{
    dispatch_async(dispatch_get_global_queue(0, 0),^ {
        callback([self getAll:url]);
    });
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)getRaw:(NSString*)url finished:(DCModelBlock)callback
{
    dispatch_async(dispatch_get_global_queue(0, 0),^ {
        callback([self getRaw:url]);
    });
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)all:(NSArray*)sortDescriptors finished:(DCModelBlock)callback
{
    [self where:nil sort:sortDescriptors limit:0 finished:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)all:(DCModelBlock)callback
{
    [self where:nil sort:nil limit:0 finished:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)where:(id)search finished:(DCModelBlock)callback
{
    [self where:search sort:nil limit:0 finished:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)where:(id)search sort:(NSArray*)sortDescriptors finished:(DCModelBlock)callback
{
    [self where:search sort:sortDescriptors limit:0 finished:callback];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit finished:(DCModelBlock)callback
{
    [self addDiskOperation:^{
        NSArray* items = [self where:search sort:sortDescriptors limit:limit];
        callback(items);
    }];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)saveObjects:(NSArray*)objects
{
    [self addDiskOperation:^{
        for(NSManagedObject* object in objects)
        {
            if(![object isDuplicate:[object class]])
                [[self objectCtx] insertObject:object];
        }
        [[self objectCtx] save:nil];
    }];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)saveObject:(NSManagedObject*)object
{
    [self addDiskOperation:^{
        if(![object isDuplicate:[object class]])
            [[self objectCtx] insertObject:object];
        [[self objectCtx] save:nil];
    }];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)destroyObject:(NSManagedObject*)object
{
    [NSManagedObject addDiskOperation:^{
        [[self objectCtx] deleteObject:object];
        [[self objectCtx] save:nil];
    }];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)destroyObjects:(NSArray*)objects
{
    [self addDiskOperation:^{
        for(NSManagedObject* object in objects)
            [[self objectCtx] deleteObject:object];
        [[self objectCtx] save:nil];
    }];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)create:(NSDictionary*)dict
{
    id managedObject = [self newObject:dict];
    [managedObject save];
    return managedObject;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//unrecommend sync methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)get:(NSString*)url
{
    NSData* response = [self fetchNetworkContent:url];
    id entries = [self createJSONObject:response];
    if(!entries)
        return nil;
    if([entries isKindOfClass:[NSDictionary class]])
    {
        NSManagedObject* object = [self newObject];
        [self processDict:entries object:object];
        return object;
    }
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)getAll:(NSString*)url
{
    NSData* response = [self fetchNetworkContent:url];
    id entries = [self createJSONObject:response];
    if(!entries)
        return nil;
    if([entries isKindOfClass:[NSDictionary class]])
    {
        if([entries count] == 1)
        {
            for(id key in entries)
                entries = [entries objectForKey:key];
        }
    }
    else if([entries isKindOfClass:[NSArray class]])
    {
        NSMutableArray* gather = [NSMutableArray arrayWithCapacity:[entries count]];
        for(NSDictionary* entry in entries)
        {
            NSManagedObject* object = [self newObject];
            [self processDict:entry object:object];
            [gather addObject:object];
        }
        return gather;
    }
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)getRaw:(NSString*)url
{
    NSData* response = [self fetchNetworkContent:url];
    id entries = [self createJSONObject:response];
    return entries;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)all
{
    return [self where:nil sort:nil];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)allSorted:(NSArray*)sortDescriptors
{
    return [self where:nil sort:sortDescriptors limit:0];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)where:(id)search
{
    return [self where:search sort:nil limit:0];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors 
{
    return [self where:search sort:nil limit:0];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self objectCtx]];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    [request setSortDescriptors:sortDescriptors];
    request.predicate = [self processSearch:search];
    if(limit > 0)
        [request setFetchLimit:limit];
    return [[self objectCtx] executeFetchRequest:request error:nil];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//public methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)clearDiskStorage
{
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:DBName]];
    NSPersistentStore* store = [[self persistentStoreCoordinator] persistentStoreForURL:storeUrl];
    [[self persistentStoreCoordinator] removePersistentStore:store error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:nil];
    persistentStoreCoordinator = nil;
    managedObjectModel = nil;
    objectCtx = nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)entityName
{
    return [self getClassName:[self class]];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)fetchNetworkContent:(NSString*)url
{
    GPHTTPRequest *request = [GPHTTPRequest requestWithString:url];
    [request setCacheTimeout:15];
    [request setCacheModel:GPHTTPCacheCustomTime];
    [request startSync];
    return [request responseData];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//local public methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSManagedObjectContext*)objectCtx
{
    if (objectCtx)
        return objectCtx;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
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
     managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;
    
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:DBName]];
    
    NSDictionary *options = nil;
    /*if(self.migrationModelName)
    {
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                   [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    }*/
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error])
    {
        NSLog(@"error: %@ userInfo: %@",error,[error userInfo]);
        static BOOL didReload;
        if(!didReload)
        {
            NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:DBName]];
            [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:nil];
            persistentStoreCoordinator = nil;
            managedObjectModel = nil;
            [NSManagedObject persistentStoreCoordinator];
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
+(NSPredicate*)processSearch:(id)search
{
    if(!search)
        return nil;
    if([search isKindOfClass:[NSPredicate class]])
        return search;
    else if([search isKindOfClass:[NSString class]])
        return [NSPredicate predicateWithFormat:search];
    else if([search isKindOfClass:[NSDictionary class]])
    {
        NSMutableString* queryString = [NSMutableString new];
        int i = 0;
        int count = [search count];
        for(id key in search)
        {
            [queryString appendFormat:@"%@ == %@", key, [search valueForKey:key]];
            i++;
            if(i < count)
                [queryString appendString:@" AND "];
        }
        return [NSPredicate predicateWithFormat:search];
    }
    
    return nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)createJSONObject:(NSData*)data
{
    id entries = nil;
    if([data respondsToSelector:@selector(objectFromJSONData)])
        entries = [data performSelector:@selector(objectFromJSONData)];
    else
        entries = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return entries;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)processDict:(NSDictionary*)entry object:(id)object
{
    for(NSString* key in entry)
    {
        if([object respondsToSelector:NSSelectorFromString(key)])
        {
            id value = [entry objectForKey:key];
            if([value isKindOfClass:[NSDictionary class]])
            {
                id childObj = [object valueForKey:key];
                if(!childObj)
                {
                    if([childObj isKindOfClass:[NSManagedObject class]])
                        childObj = [[childObj class] newObject];
                    else
                        childObj = [[[childObj class] alloc] init];
                }
                [self processDict:value object:childObj];
            }
            else if([NSNull null] != (NSNull*)value)
                [object setValue:[entry objectForKey:key] forKey:key];
        }
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@end
