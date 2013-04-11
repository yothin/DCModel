///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCModel.h
//
//  Created by Dalton Cherry on 4/11/13.
//  Copyright 2013 Basement Krew. All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@class DCModel;

typedef void (^DCModelBlock)(NSArray* items);

@interface DCModel : NSObject

//fetches an object show route from the network.(e.g. /user/1.json)
+(void)get:(NSString*)url finished:(DCModelBlock)callback;

//fetches an object index route from the network.(e.g. /users.json)
+(void)getAll:(NSString*)url finished:(DCModelBlock)callback;

//pulls all the objects of this table from the coreData. Pass a sort Descriptor if you want them sorted
+(void)all:(NSArray*)sortDescriptors finished:(DCModelBlock)callback;

//pulls all the objects of this table from the coreData
+(void)all:(DCModelBlock)callback;

//find an object of this table from coreData
+(void)find:(NSPredicate*)predicate sort:(NSArray*)sortDescriptors finished:(DCModelBlock)callback;

//does a batch save of all the objects.
+(void)saveObjects:(NSArray*)objects;

//unrecommend sync methods

//fetches an object show route from the network.(e.g. /user/1.json)
+(id)get:(NSString*)url;

//fetches an object index route from the network.(e.g. /users.json)
+(NSArray*)getAll:(NSString*)url;

//pulls all the objects of this table from the coreData
+(NSArray*)all;

//pulls all the objects of this table from the coreData
+(NSArray*)allSorted:(NSArray*)sortDescriptors;

//find an object of this table from coreData
+(NSArray*)find:(NSPredicate*)predicate sort:(NSArray*)sortDescriptors;


//use to clear a all contents of a DB from disk.
+(void)clearDiskStorage;

@end
