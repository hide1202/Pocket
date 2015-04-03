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
static const NSString* kDefaultDbFileName = @"default.sqlite";

@interface PocketBase : NSObject
-(instancetype)init;
-(instancetype)initWithProperties:(NSArray*)props;
-(instancetype)initWithProperties:(NSArray*)props primaryKeys:(NSArray*)pKeys;

-(void)setProperties:(NSArray*)properties;
-(void)setPrimaryKey:(NSArray*)pKeys;

-(BOOL)insert;
-(BOOL)update;
-(void)loadWithPrimaryKey:(NSDictionary*)pKeys completionHandler:(void(^)(NSError*))handler;
-(void)load;

-(BOOL)deleteDbForTest;

@property (nonatomic, retain) NSString* tableName;
@property (nonatomic, retain, readonly) NSDictionary* primaryKeys;
@property (nonatomic, retain, readonly) NSDictionary* properties;
@end

#endif