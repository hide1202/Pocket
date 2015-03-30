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
#import "PocketSqlManager.h"

@interface Property : NSObject
-(id)invoke:(id)target;
-(NSString*)type:(id)target;
@property objc_property_t property;
@end

@implementation Property
-(NSString*)type:(id)target
{
	id result = [self invoke:target];
	
	if([[result class] isSubclassOfClass:[NSNumber class]])
	{
		if(CFNumberIsFloatType((CFNumberRef)result))
			return kReal;
		else
			return kInteger;
	}
	else if([[result class] isSubclassOfClass:[NSString class]])
		return kText;
	
	return nil;
}
-(id)invoke:(id)target
{
	SEL msg = NSSelectorFromString([NSString stringWithUTF8String: property_getName(_property)]);
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:msg]];
	[inv setSelector:msg];
	[inv invokeWithTarget:target];
	id result = nil;
	[inv getReturnValue:&result];
	
	return result;
}
@end

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
		_manager = [[PocketSqlManager alloc] initWithDbName:[NSString stringWithUTF8String:kPocketDbName]];
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
	
	NSMutableString* columns = [NSMutableString new];
	for (NSString* name in [_props allKeys]) {
		[columns appendFormat:@",%@", name];
	}
	
	NSMutableString* whereClause = [NSMutableString new];
	for (NSString* name in [pKeys allKeys]) {
		[whereClause appendFormat:@"and %@ = %@", name, pKeys[name]];
	}
	
	NSString* query = [NSString stringWithFormat:@"select %@ from %@ where (%@)", [columns substringFromIndex:1], self.tableName, [whereClause substringFromIndex:4]];
	NSLog(@"Select query : %@", query);
	[_manager executeQuery:query resultHandler:^(NSArray *result) {
		int i = 0;
		for (NSString* name in _props) {
			NSString* setterName = [NSString stringWithFormat:@"set%@:", [name capitalizedString]];
			NSLog(@"Setter name : %@", setterName);
			SEL msg = NSSelectorFromString(setterName);
			if([self respondsToSelector:msg])
			{
				id arg = result[i++];
				NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:msg]];
				[inv setSelector:msg];
				[inv setArgument:&arg atIndex:2];
				[inv invokeWithTarget:self];
			}
		}

		handler(nil);
	}];
}
@end