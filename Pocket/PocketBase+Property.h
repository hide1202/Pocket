//
//  PocketBase+Property.h
//  Pocket
//
//  Created by VIEWPOINT on 2015. 4. 1..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#ifndef Pocket_PocketBase_Property_h
#define Pocket_PocketBase_Property_h

#import <objc/runtime.h>
#import "PocketConst.h"

@interface Property : NSObject
+(instancetype)propertyWithName:(NSString*)name target:(id)target;
-(id)invoke:(id)target;
-(NSString*)type:(id)target;
-(void)insection:(id)target value:(id)value;
@property objc_property_t property;
@property NSString* name;
@end

@implementation Property
+(instancetype)propertyWithName:(NSString*)name target:(id)target
{
	Property* p = [Property new];
	if(p)
	{
		p->_name = name;
		p.property = class_getProperty([target class], [name UTF8String]);
		if(!p.property)
			[NSException raise:@"PocketBaseException" format:@"This class doesn't contain %@ property", name];
	}
	return p;
}

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

-(void)insection:(id)target value:(id)value
{
	NSString* setterName = [NSString stringWithFormat:@"set%@:", [self->_name capitalizedString]];
	//NSLog(@"Setter name : %@", setterName);
	SEL msg = NSSelectorFromString(setterName);
	if([target respondsToSelector:msg])
	{
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:msg]];
		[inv setSelector:msg];
		[inv setArgument:&value atIndex:2];
		[inv invokeWithTarget:target];
	}
}
@end

#endif
