//
//  PocketBase+Load.h
//  Pocket
//
//  Created by VIEWPOINT on 2015. 4. 1..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#ifndef Pocket_PocketBase_Load_h
#define Pocket_PocketBase_Load_h

#import "PocketBase+Property.h"

@interface PocketBase (Load)
-(NSString*)selectColumns:(NSMutableDictionary*)properties;
-(NSString*)where;
-(NSString*)whereWithDict:(NSDictionary*)dict;
-(void)insection:(NSArray*)resultSet;
@end

@implementation PocketBase (Load)
-(NSString*)selectColumns:(NSMutableDictionary*)properties
{
	NSMutableString* columns = [NSMutableString new];
	for (NSString* name in [properties allKeys])
		[columns appendFormat:@",%@", name];
	return [columns substringFromIndex:1];
}

-(NSString*)where
{
	NSMutableString* whereClause = [NSMutableString new];
	for (NSString* name in [self.primaryKeys allKeys])
		[whereClause appendFormat:@"and %@ = %@", name, [self.primaryKeys[name] invoke:self]];
	return [whereClause substringFromIndex:4];
}

-(NSString*)whereWithDict:(NSDictionary*)dict
{
	NSMutableString* whereClause = [NSMutableString new];
	for (NSString* name in [dict allKeys])
		[whereClause appendFormat:@"and %@ = %@", name, dict[name]];
	return [whereClause substringFromIndex:4];
}

-(void)insection:(NSArray*)resultSet
{
	int i = 0;
	for (NSString* name in [self properties])
	{
		NSString* setterName = [NSString stringWithFormat:@"set%@:", [name capitalizedString]];
		//NSLog(@"Setter name : %@", setterName);
		SEL msg = NSSelectorFromString(setterName);
		if([self respondsToSelector:msg])
		{
			id arg = resultSet[i++];
			NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:msg]];
			[inv setSelector:msg];
			[inv setArgument:&arg atIndex:2];
			[inv invokeWithTarget:self];
		}
	}
}
@end

#endif
