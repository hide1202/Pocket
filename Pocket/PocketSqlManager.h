//
//  PocketSqlManager.h
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 29..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#ifndef Pocket_SqlManager_h
#define Pocket_SqlManager_h

#define kInteger (@"integer")
#define kText (@"text")
#define kReal (@"real")

@interface PocketSqlManager : NSObject
-(instancetype)initWithDbName:(NSString*)fileName;
-(instancetype)initWithDbName:(NSString*)fileName directory:(NSSearchPathDirectory)directory;

-(BOOL) deleteDatabase;
-(BOOL) executeQuery:(NSString*)query;
-(BOOL) executeQuery:(NSString*)query resultHandler:(void(^)(NSArray*))handler;
@end

#endif
