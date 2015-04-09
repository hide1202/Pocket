//
//  PocketBaseTest.m
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 29..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PocketSqlManager.h"

@interface PocketSqlManagerTest : XCTestCase

@end

@implementation PocketSqlManagerTest
{
	PocketSqlManager* _sqlManager;
}

- (void)setUp {
    [super setUp];
	[PocketSqlManager initializeWithDbName:@"testtable.db"];
	_sqlManager = [PocketSqlManager manager];
	[_sqlManager executeQuery:@"create table test(num integer)"];
}

- (void)tearDown {
    [super tearDown];
	NSLog(@"Delete database result : %@", [_sqlManager deleteDatabase] ? @"true" : @"false");
}

- (void)testExample {
	XCTestExpectation * expection = [self expectationWithDescription:@"select test"];
	BOOL result1 = [_sqlManager executeQuery:@"insert into test(num) values(1)"];
	
	[_sqlManager executeQueryAsync:@"select * from test" resultHandler:^(NSArray *result) {
		XCTAssert([[[result objectAtIndex:0] objectForKey:@"num"] isEqual:@1], @"Pass");
		[expection fulfill];
	}];
    XCTAssert(result1, @"Pass");
	
	[self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
	}];
}

@end
