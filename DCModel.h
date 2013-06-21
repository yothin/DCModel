///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCModel.h
//
//  Created by Dalton Cherry on 4/11/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

//@class DCModel;

typedef void (^DCModelBlock)(id items);

typedef id (^DCModelParseBlock)(id jsonObj);

@interface NSManagedObject (ActiveRecord)

//deletes the current object from coreData
-(void)destroy;

//this just runs the class save method
-(void)save;

//checks on disk if object already exist
- (BOOL)isDuplicate:(Class)class;

//override and set one of your properties to be a primary key (if needed) 
+(NSString*)primaryKey;

//fetches an object show route from the network.(e.g. /user/1.json)
+(void)get:(NSString*)url finished:(DCModelBlock)callback;

//fetches an object index route from the network.(e.g. /users.json)
+(void)getAll:(NSString*)url finished:(DCModelBlock)callback;

//fetches an raw json and returns it from the network.
+(void)getRaw:(NSString*)url parse:(DCModelParseBlock)parseBlock finished:(DCModelBlock)callback;

//pulls all the objects of this table from the coreData. Pass a sort Descriptor if you want them sorted
+(void)all:(NSArray*)sortDescriptors finished:(DCModelBlock)callback;

//pulls all the objects of this table from the coreData
+(void)all:(DCModelBlock)callback;

//find an object of this table from coreData
+(void)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit finished:(DCModelBlock)callback;

//find an object of this table from coreData
+(void)where:(id)search sort:(NSArray*)sortDescriptors finished:(DCModelBlock)callback;

//find an object of this table from coreData
+(void)where:(id)search finished:(DCModelBlock)callback;

//does a batch save of all the objects.
+(void)saveObjects:(NSArray*)objects;

//saves an object
+(void)saveObject:(NSManagedObject*)object;

//delete an object
+(void)destroyObject:(NSManagedObject*)object;

//delete a group of objects
+(void)destroyObjects:(NSArray*)objects;

//creates a new object and saves it to disk
+(id)create:(NSDictionary*)dict;

//creates a new object, but does NOT save it disk. You need to save it manually.
+(id)newObject;

//creates a new object, but does NOT save it disk. You need to save it manually.
+(id)newObject:(NSDictionary*)dict;

//unrecommend sync methods. These are NOT thread safe.

//fetches an object show route from the network.(e.g. /user/1.json)
+(id)get:(NSString*)url;

//fetches an object index route from the network.(e.g. /users.json)
+(NSArray*)getAll:(NSString*)url;

//fetches an raw json and returns it from the network.
+(id)getRaw:(NSString*)url;

//pulls all the objects of this table from the coreData
+(NSArray*)all;

//pulls all the objects of this table from the coreData
+(NSArray*)allSorted:(NSArray*)sortDescriptors;

//find an object of this table from coreData
+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors;

+(NSArray*)where:(id)search;

+(NSArray*)where:(id)search sort:(NSArray*)sortDescriptors limit:(NSInteger)limit;

//returns the entityName of the coreData entity. By Default it returns the className.
//override this in your subclass if you have a different name.
+(NSString*)entityName;

//use to clear a all contents of a DB from disk. 
+(void)clearDiskStorage;

//use this to stop all async DB operations
+(void)stopOperations;

//I am exposing this, so incase you need to use it your subclass.
+(NSData*)fetchNetworkContent:(NSString*)url;
+(id)createJSONObject:(NSData*)data;

@end

