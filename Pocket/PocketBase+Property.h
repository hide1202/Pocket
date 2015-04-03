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
@property objc_property_t property;
@end

@implementation Property
+(instancetype)propertyWithName:(NSString*)name target:(id)target
{
	Property* p = [Property new];
	if(p)
	{
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
@end

#endif
