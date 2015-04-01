//
//  PocketBase.m
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 30..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
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

@synthesize properties = _props;
@synthesize primaryKeys = _pKeys;

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self->_isCreate = NO;
		self.tableName = NSStringFromClass([self class]);
		NSString* dbFileName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kDbFileNameKey] copy];

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

-(void)setProperties:(NSArray*)properties
{
	if(!_props)	_props = [NSMutableDictionary new];
	else		[_props removeAllObjects];
	
	for (NSString* name in properties)
	{
		Property* prop = [Property new];
		prop.property = class_getProperty([self class], [name UTF8String]);
		if(!prop.property)
			[NSException raise:@"PocketBaseException" format:@"This class doesn't contaion %@ property", name];
		[_props setValue:prop forKey:name];
	}
}

-(void)setPrimaryKey:(NSArray*)pKeys
{
	_pKeys = [NSMutableDictionary new];
	for (NSString* name in pKeys)
	{
		Property* prop = [Property new];
		prop.property = class_getProperty([self class], [name UTF8String]);
		if(!prop.property)
			[NSException raise:@"PocketBaseException" format:@"This class doesn't contaion %@ property", name];
		[_pKeys setValue:prop forKey:name];
	}
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
	NSString* query = [NSString stringWithFormat:@"insert into %@(%@) values(%@)", _tableName, [columns substringFromIndex:1], [values substringFromIndex:1]];
	NSLog(@"Insert query : %@", query);
	return [_manager executeQuery:query];
}

-(BOOL)createDatabase
{
	NSMutableString* columns = [NSMutableString new];
	for (NSString* name in [_props allKeys]) {
		[columns appendFormat:@",%@ %@", name, [_props[name] type:self]];
	}
	
	NSString* query = [NSString stringWithFormat:@"create table %@(%@)", _tableName, [columns substringFromIndex:1]];
	NSLog(@"Create query : %@", query);
	_isCreate = [_manager executeQuery:query];
	return _isCreate;
}

-(BOOL)deleteDbForTest
{
	return [_manager deleteDatabase];
}

-(void)loadWithPrimaryKey:(NSDictionary*)pKeys completionHandler:(void(^)(NSError*))handler;
{
	if(_pKeys == nil || [_pKeys count] == 0)
		handler([NSError errorWithDomain:@"PocketBase" code:-1 userInfo:nil]);
	
	NSString* query = [NSString stringWithFormat:@"select %@ from %@ where (%@)", [self selectColumns:_props], self.tableName, [self whereWithDict:pKeys]];
	NSLog(@"Select query : %@", query);
	[_manager executeQueryAsync:query resultHandler:^(NSArray *result) {
		[self insection:result];
		handler(nil);
	}];
}

-(void)load
{
	if(_pKeys == nil || [_pKeys count] == 0)
		[NSException raise:@"PocketBase" format:@"Primary key doesn't be found"];
	
	NSString* query = [NSString stringWithFormat:@"select %@ from %@ where (%@)", [self selectColumns:_props], self.tableName, [self where]];
	NSLog(@"Select query : %@", query);
	[self insection:[_manager executeQuerySync:query]];
}
@end