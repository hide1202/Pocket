//
//  PocketBaseTest.m
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 30..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PocketBase.h"

@interface TestModel : PocketBase
@property NSNumber* id;
@property NSNumber* num;
@property NSNumber* age;
@property NSString* name;
@end

@implementation TestModel
@end

@interface PocketBaseTest : XCTestCase
@end

@implementation PocketBaseTest
{
	TestModel* _model;
}
- (void)setUp {
    [super setUp];
	
	_model = [[TestModel alloc] initWithProperties:@[@"id",@"num",@"name",@"age"]];
	[_model setPrimaryKey:@[@"id"]];
}

- (void)tearDown {
    [super tearDown];
	NSLog(@"delete db : %@", [_model deleteDbForTest] ? @"true" : @"false");
}

- (void)testExample {
	XCTestExpectation * expection = [self expectationWithDescription:@"load test"];
	_model.id = @1;
	_model.num = @999;
	_model.name = @"VIEWPOINT";
	_model.age = @28;
    XCTAssert([_model insert], @"Pass");
	_model.id = @5;
	_model.num = @20;
	[_model loadWithPrimaryKey:@{@"id":@1} completionHandler:^(NSError *e) {
		XCTAssert(e==nil, @"Pass");
		XCTAssert([_model.id isEqualToNumber:@1], @"Pass");
		XCTAssert([_model.num isEqualToNumber:@999], @"Pass");
		
		_model.id = @1;
		_model.num = @20;
		[_model load];
		XCTAssert([_model.id isEqualToNumber:@1], @"Pass");
		XCTAssert([_model.num isEqualToNumber:@999], @"Pass");
		
		[expection fulfill];
	}];
	
	[self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
		NSLog(@"Error : %@", error);
	}];
}

-(void)testUpdate
{
	TestModel* model = [[TestModel alloc] initWithProperties:@[@"id",@"num"] primaryKeys:@[@"id"]];
	
	/*
	 [Memory]
	 id = 1, num = 10
	 [DB]
	 id = 1, num = 10
	 */
	model.id = @1;
	model.num = @10;
	[model insert];
	
	/*
	 [Memory]
	 id = 1, num = 100
	 [DB]
	 id = 1, num = 100
	 */
	model.num = @100;
	[model update];
	
	/*
	 [Memory]
	 id = 1, num = 900
	 [DB]
	 id = 1, num = 100
	 [After load]
	 id = 1, num = 100
	 */
	model.num = @900;
	[model load];
	XCTAssert([model.num isEqualToNumber:@100], @"Pass");
}

- (void)testPerformanceExample {
    [self measureBlock:^{
    }];
}

@end
