//
//  PocketBase.m
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 30..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PocketConst.h"
#import "PocketBase.h"
#import "PocketBase+Property.h"
#import "PocketBase+Load.h"
#import "PocketSqlManager.h"

@interface PocketBase ()
-(BOOL)createDatabase;
@end

@implementation PocketBase
{
@private
	BOOL _isCreate;
	NSMutableDictionary* _props;
	NSMutableDictionary* _pKeys;
	PocketSqlManager* _manager;
}

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self->_isCreate = NO;
		self.tableName = NSStringFromClass([self class]);
		NSString* dbFileName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kDbFileNameKey];

		if(!dbFileName)
			dbFileName = (NSString*)kDefaultDbFileName;
		
		NSLog(@"Db file name : %@", dbFileName);
		_manager = [[PocketSqlManager alloc] initWithDbName:dbFileName];
	}
	return self;
}

-(instancetype)initWithProperties:(NSArray*)props
{
	self = [self init];
	if(self)
		[self setProperties:props];
	return self;
}

-(instancetype)initWithProperties:(NSArray*)props primaryKeys:(NSArray*)pKeys
{
	self = [self initWithProperties:props];
	if(self)
		[self setPrimaryKey:pKeys];
	return self;
}

-(NSDictionary*) primaryKeys
{
	return self->_pKeys;
}

-(NSDictionary*) properties
{
	return self->_props;
}

-(void)setProperties:(NSArray*)properties
{
	if(!_props)	_props = [NSMutableDictionary new];
	else		[_props removeAllObjects];
	
	for (NSString* name in properties)
		[_props setValue:[Property propertyWithName:name target:self] forKey:name];
}

-(void)setPrimaryKey:(NSArray*)pKeys
{
	if(!_pKeys)	_pKeys = [NSMutableDictionary new];
	else		[_pKeys removeAllObjects];
	
	for (NSString* name in pKeys)
		[_pKeys setValue:[Property propertyWithName:name target:self] forKey:name];
}

-(BOOL)insert
{
	if(!_isCreate) [self createDatabase];
	
	NSMutableString* columns = [NSMutableString new];
	NSMutableString* values = [NSMutableString new];
	for (NSString* name in [_props allKeys])
	{
		[columns appendFormat:@",%@", name];
		SEL msg = NSSelectorFromString(name);
		
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:msg]];
		
		[inv setTarget:self];
		[inv setSelector:msg];
		
		[inv invoke];
		
		id result;
		[inv getReturnValue:&result];
		
		if([[_props[name] type:self] isEqualToString:@"text"])
			[values appendFormat:@",'%@'", result];
		else
			[values appendFormat:@",%@", result];
	}
	NSString* query = [NSString stringWithFormat:kInsertQuery, _tableName, [columns substringFromIndex:1], [values substringFromIndex:1]];
	NSLog(@"Insert query : %@", query);
	return [_manager executeQuery:query];
}

-(BOOL)update
{	
	NSMutableString* setClause = [[NSMutableString alloc] init];
	for (NSString* name in [_props allKeys])
	{
		id value = [_props[name] invoke:self];
		if([[value class] isSubclassOfClass:[NSString class]])
			[setClause appendFormat:@",%@='%@'", name, value];
		else
			[setClause appendFormat:@",%@=%@", name, value];
	}
	
	NSString* query = [NSString stringWithFormat:kUpdateQuery, self.tableName, [setClause substringFromIndex:1] , [self where]];
	NSLog(@"Update query : %@", query);
	return [_manager executeQuery:query];
}

-(BOOL)createDatabase
{
	NSMutableString* columns = [NSMutableString new];
	for (NSString* name in [_props allKeys]) {
		[columns appendFormat:@",%@ %@", name, [_props[name] type:self]];
	}
	
	NSString* query = [NSString stringWithFormat:kCreateQuery, _tableName, [columns substringFromIndex:1]];
	NSLog(@"Create query : %@", query);
	_isCreate = [_manager executeQuery:query];
	return _isCreate;
}

-(BOOL)deleteDbForTest
{
	return [_manager deleteDatabase];
}

-(void)viewDbForTest
{
	[_manager selectAllForTest:self.tableName];
}

-(void)loadWithPrimaryKey:(NSDictionary*)pKeys completionHandler:(void(^)(NSError*))handler;
{
	if(_pKeys == nil || [_pKeys count] == 0)
	{
		handler([NSError errorWithDomain:@"PocketBase" code:-1 userInfo:nil]);
		return;
	}
	
	NSString* query = [NSString stringWithFormat:kSFWQuery, [self selectColumns:_props], self.tableName, [self whereWithDict:pKeys]];
	[_manager executeQueryAsync:query resultHandler:^(NSArray *result) {
		[self insection:result];
		handler(nil);
	}];
}

-(void)load
{
	if(_pKeys == nil || [_pKeys count] == 0)
		[NSException raise:@"PocketBase" format:@"Primary key doesn't be found"];
	
	NSString* query = [NSString stringWithFormat:kSFWQuery, [self selectColumns:_props], self.tableName, [self where]];
	[self insection:[_manager executeQuerySync:query]];
}
@end