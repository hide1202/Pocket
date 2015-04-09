//
//  PocketBase.h
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 30..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#ifndef Pocket_Base_h
#define Pocket_Base_h

static const NSString* kDbFileNameKey = @"PocketDbFileName";
static const NSString* kDefaultDbFileName = @"PocketDb.sqlite";

@class PocketSqlManager;

@interface PocketBase : NSObject
+(NSArray*)allLoad;

-(instancetype)init;
-(instancetype)initWithProperties:(NSArray*)props;
-(instancetype)initWithProperties:(NSArray*)props primaryKeys:(NSArray*)pKeys;

-(void)setProperties:(NSArray*)properties;
-(void)setPrimaryKey:(NSArray*)pKeys;
-(NSDictionary*) primaryKeys;
-(NSDictionary*) properties;

-(BOOL)insert;
-(BOOL)update;
-(void)loadWithPrimaryKey:(NSDictionary*)pKeys completionHandler:(void(^)(NSError*))handler;
-(void)load;

-(BOOL)deleteDbForTest;
-(void)viewDbForTest;

@property (nonatomic, retain) NSString* tableName;
@end

#endif