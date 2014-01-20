////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCModel.h
//
//  Created by Dalton Cherry on 4/11/13.
//
//  Overall I believe a more efficent way to handle this would be to use SQLLite directly.
//  This would require quite a bit more time investment, so I am going to this to get as close as we can.
//  With that said, this framework is designed to be completely functional and never touch the main thread with coreData queries.
//  So you should not have problem with coreData threading safety or blocking, pretty handy stuff.
////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^DCModelBlock)(id items);

typedef void (^DCModelFailureBlock)(NSError* error);

typedef void (^DCModelFailDestroy)(void);

typedef id (^DCModelParseBlock)(id jsonObj);

@interface NSManagedObject (ActiveRecord)

///-------------------------------
/// @name Instance Methods
///-------------------------------

/**
 Runs the class method DestoryObject with self as the object
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
-(void)destroy:(DCModelFailDestroy)success failure:(DCModelFailureBlock)failure;

/**
 Runs the class method save with self as the object
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
-(void)save:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Runs the class method saveOrUpdate with self as the object
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
-(void)saveOrUpdate:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Runs the class method saveOrUpdate with self as the object
 @param The success block is called once coreData is finished processing.
 @param keys is the properties you want to update
 @param The failure block is called if an error is encountered.
 */
-(void)saveOrUpdate:(DCModelBlock)success properties:(NSArray*)keys failure:(DCModelFailureBlock)failure;

///-------------------------------
/// @name Asynchronous and Thread Safe Methods
///-------------------------------

/**
 This validates the NSManagedObject against each other. This works by querying on this key for objects that match this value.
 By default this is "objID".
 */
+(NSString*)primaryKey;

/**
 Fetchs all the objects of this table from the coreData. Pass a sort Descriptor if you want them sorted
 @param The success block is called once coreData is finished processing.
 */
+(void)all:(NSArray*)sortDescriptors success:(DCModelBlock)success;

/**
 Fetchs all the objects of this table from the coreData.
 @param The success block is called once coreData is finished processing.
 */
+(void)all:(DCModelBlock)success;

/**
 Find an object of this table from coreData.
 @param Pass a sort Descriptor if you want them sorted.
 @param Pass limit to limit the amount of objects returned.
 @param The success block is called once coreData is finished processing.
 */
+(void)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit success:(DCModelBlock)success;

/**
 Find an object of this table from coreData.
 @param Pass a sort Descriptor if you want them sorted.
 @param The success block is called once coreData is finished processing.
 */
+(void)where:(id)search sort:(NSArray*)sortDescriptors success:(DCModelBlock)success;

/**
 Find an object of this table from coreData.
 @param search if the search string or predicate to find
 @param The success block is called once coreData is finished processing.
 */
+(void)where:(id)search success:(DCModelBlock)success;

/**
 Does a batch save of all the objects. This saves/clears the object context so all changes staged for coreData are commited/saved.
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
+(void)saveObjects:(NSArray*)objects success:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Saves a single object. This saves/clears the object context so all changes staged for coreData are commited/saved.
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
+(void)saveObject:(NSManagedObject*)object success:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Does a batch update and saves any objects that aren't in coreData. This saves/clears the object context so all changes staged for coreData are commited/saved.
 @param objects are the multiple objects to update.
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
+(void)updateObjects:(NSArray*)objects success:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Does a batch update and saves any objects that aren't in coreData. This saves/clears the object context so all changes staged for coreData are commited/saved.
 @param objects are the multiple objects to update.
 @param keys is the properties you want to update
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
+(void)updateObjects:(NSArray*)objects properties:(NSArray*)keys success:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Does an update or save on a single object. This saves/clears the object context so all changes staged for coreData are commited/saved.
 @param object is the object to update.
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
+(void)updateObject:(id)object success:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Does an update or save on a single object. This saves/clears the object context so all changes staged for coreData are commited/saved.
 @param object is the object to update.
 @param keys is the properties you want to update
 @param The success block is called once coreData is finished processing.
 @param The failure block is called if an error is encountered.
 */
+(void)updateObject:(id)object properties:(NSArray*)keys success:(DCModelBlock)success failure:(DCModelFailureBlock)failure;

/**
 Does a delete on the single object. This saves/clears the object context so all changes staged for coreData are commited/saved.
 The success block is called once coreData is finished processing.
 The failure block is called if an error is encountered.
 */
+(void)destroyObject:(NSManagedObject*)object success:(DCModelFailDestroy)success failure:(DCModelFailureBlock)failure;

/**
 Does a batch delete of the objects. This saves/clears the object context so all changes staged for coreData are commited/saved.
 The success block is called once coreData is finished processing.
 The failure block is called if an error is encountered.
 */
+(void)destroyObjects:(NSArray*)objects success:(DCModelFailDestroy)success failure:(DCModelFailureBlock)failure;

/**
Creates a new object and adds it to the managed context. This saves/clears the object context so all changes staged for coreData are commited/saved.
 */
+(id)create:(NSDictionary*)dict;

/**
 Creates a new object, but does add it to managed context. You need to save it manually by calling save.
 */
+(id)newObject;

/**
 Does the same thing as newObject, but is needed for certain runtime init on different libraries.
 */
+(id)newModel;

/**
 Creates a new object, but does add it to managed context. You need to save it manually by calling save.
 Dict is a NSDictionary of values you want to assign to properties you have.
 */
+(id)newObject:(NSDictionary*)dict;

///-------------------------------
/// @name Synchronous and NOT Thread Safe Methods
///-------------------------------

/**
 Returns all the objects of this table from the coreData.
 */
+(NSArray*)all;

/**
 Returns all the objects of this table from the coreData.
 Pass a sort Descriptor if you want them sorted.
 */
+(NSArray*)allSorted:(NSArray*)sortDescriptors;

/**
 Find an object of this table from coreData and return it.
 Pass a sort Descriptor if you want them sorted.
 */
+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors;

/**
 Find an object of this table from coreData and return it.
 */
+(NSArray*)where:(id)search;

/**
 Find an object of this table from coreData and return it.
 Pass a sort Descriptor if you want them sorted.
 Pass limit to limit the amount of objects returned.
 */
+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit;

/**
 Deletes the objects and returns if it was successful or not.
 */
+(BOOL)syncDeleteObjects:(NSArray*)objects;

/**
 Returns the entityName of the coreData entity. By Default it returns the className.
 */
+(NSString*)entityName;

//use to clear a all contents of a DB from disk.
/**
 This deletes all the content of the SQLLite store.
 */
+(void)clearDiskStorage;

/**
 This stops all the operations in the queue.
 */
+(void)stopOperations;

/**
 Blocks the current thread until all operations complete
 */
+(void)wait;

@end

