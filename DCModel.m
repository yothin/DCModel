////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCModel.m
//
//  Created by Dalton Cherry on 4/11/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCModel.h"
#import <objc/runtime.h>

@implementation NSManagedObject (ActiveRecord)

static NSManagedObjectContext* objectCtx;
static NSManagedObjectModel* managedObjectModel;
static NSPersistentStoreCoordinator* persistentStoreCoordinator;
static NSOperationQueue* diskQueue;
static NSString* const DBName = @"dcmodel.sqlite";

typedef void (^DiskCallBack)(void);

////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)newObject
{
    return [self newObject:nil];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)destroy:(DCModelFailDestroy)success failure:(DCModelFailureBlock)failure
{
    [NSManagedObject destroyObject:self success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)save:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    [NSManagedObject saveObject:self success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)saveOrUpdate:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    [NSManagedObject updateObject:self success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)primaryKey
{
    return @"objID";
}
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
//recommend async methods
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)all:(NSArray*)sortDescriptors success:(DCModelBlock)success
{
    [self where:nil sort:sortDescriptors limit:0 success:success];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)all:(DCModelBlock)success
{
    [self where:nil sort:nil limit:0 success:success];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)where:(id)search finished:(DCModelBlock)success
{
    [self where:search sort:nil limit:0 success:success];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)where:(id)search sort:(NSArray*)sortDescriptors success:(DCModelBlock)success
{
    [self where:search sort:sortDescriptors limit:0 success:success];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit success:(DCModelBlock)success
{
    [self addDiskOperation:^{
        NSArray* items = [self where:search sort:sortDescriptors limit:limit];
        dispatch_sync(dispatch_get_main_queue(), ^{
            success(items);
        });
    }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)saveObjects:(NSArray *)objects isUpdate:(BOOL)isUp success:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    [self addDiskOperation:^{
        for(NSManagedObject* object in objects)
        {
            if(![object isDuplicate:[object class] isUpdate:isUp] && [object isKindOfClass:[NSManagedObject class]])
                [[self objectCtx] insertObject:object];
        }
        NSError* error = nil;
        if(![[self objectCtx] save:&error])
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                failure(error);
            });
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            success(objects);
        });
    }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)saveObjects:(NSArray*)objects success:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    [self saveObjects:objects isUpdate:NO success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)saveObject:(NSManagedObject*)object success:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    if(object && [object isKindOfClass:[NSManagedObject class]])
        [self saveObjects:@[object] isUpdate:NO success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)updateObjects:(NSArray*)objects success:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    [self saveObjects:objects isUpdate:YES success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)updateObject:(id)object success:(DCModelBlock)success failure:(DCModelFailureBlock)failure
{
    if(object && [object isKindOfClass:[NSManagedObject class]])
        [self saveObjects:@[object] isUpdate:YES success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)destroyObject:(NSManagedObject*)object success:(DCModelFailDestroy)success failure:(DCModelFailureBlock)failure
{
    if(object)
        [self destroyObjects:@[object] success:success failure:failure];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)destroyObjects:(NSArray*)objects success:(DCModelFailDestroy)success failure:(DCModelFailureBlock)failure
{
    if(objects)
    {
        [self addDiskOperation:^{
            for(NSManagedObject* object in objects)
            {
                if([object isKindOfClass:[NSManagedObject class]])
                {
                    if(![object managedObjectContext])
                        [[self objectCtx] insertObject:object];
                    if([self objectCtx] == [object managedObjectContext])
                        [[self objectCtx] deleteObject:object];
                }
            }
            NSError* error = nil;
            if(![[self objectCtx] save:&error])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    failure(error);
                });
                return;
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                success();
            });
        }];
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(id)create:(NSDictionary*)dict
{
    id managedObject = [self newObject:dict];
    [managedObject save:NULL failure:NULL];
    return managedObject;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//unrecommend sync methods
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)all
{
    return [self where:nil sort:nil];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)allSorted:(NSArray*)sortDescriptors
{
    return [self where:nil sort:sortDescriptors limit:0];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)where:(id)search
{
    return [self where:search sort:nil limit:0];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors 
{
    return [self where:search sort:nil limit:0];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)syncDeleteObjects:(NSArray*)objects
{
    if(objects)
    {
        for(NSManagedObject* object in objects)
        {
            if([object isKindOfClass:[NSManagedObject class]])
            {
                if(![object managedObjectContext])
                    [[self objectCtx] insertObject:object];
                if([self objectCtx] == [object managedObjectContext])
                    [[self objectCtx] deleteObject:object];
            }
        }
        return [[self objectCtx] save:nil];
    }
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//public methods
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)stopOperations
{
    [diskQueue cancelAllOperations];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)entityName
{
    return [self getClassName:[self class]];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//local public methods
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)addDiskOperation:(DiskCallBack)callback
{
    if(!diskQueue)
    {
        diskQueue = [[NSOperationQueue alloc] init];
        diskQueue.maxConcurrentOperationCount = 1;
    }
    [diskQueue addOperationWithBlock:callback];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSString*)getClassName:(Class)objectClass
{
    const char* className = class_getName(objectClass);
    NSString* identifier = [[NSString alloc] initWithBytesNoCopy:(char*)className
                                                           length:strlen(className)
                                                         encoding:NSASCIIStringEncoding freeWhenDone:NO];
    return identifier;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)wait
{
    [diskQueue waitUntilAllOperationsAreFinished];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//private properties
////////////////////////////////////////////////////////////////////////////////////////////////////
//gets all the properties names of the class
+(NSArray*)getPropertiesOfClass:(Class)objectClass
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(objectClass, &outCount);
    NSMutableArray* gather = [NSMutableArray arrayWithCapacity:outCount];
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        NSString* propName = [NSString stringWithUTF8String:property_getName(property)];
        [gather addObject:propName];
    }
    free(properties);
    if([objectClass superclass] && [objectClass superclass] != [NSObject class])
        [gather addObjectsFromArray:[self getPropertiesOfClass:[objectClass superclass]]];
    return gather;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)isDuplicate:(Class)class isUpdate:(BOOL)isUp
{
    BOOL isDup = NO;
    NSString* key = [class primaryKey];
    if(key && [self respondsToSelector:NSSelectorFromString(key)])
    {
        NSArray* items = [class where:[NSString stringWithFormat:@"%@ == '%@'",key,[self valueForKey:key]] sort:nil limit:1];
        if(items.count > 0)
        {
            if(isUp)
            {
                id object = items[0];
                NSArray* props = [object getPropertiesOfClass:class];
                for(NSString* propertyName in props)
                    [object setValue:[self valueForKey:propertyName] forKey:propertyName];
            }
            isDup = YES;
        }
    }
    if([self managedObjectContext])
        return YES;
    return isDup;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
