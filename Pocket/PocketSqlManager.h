//
//  PocketSqlManager.h
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 29..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#ifndef Pocket_SqlManager_h
#define Pocket_SqlManager_h

@interface PocketSqlManager : NSObject
-(instancetype)initWithDbName:(NSString*)fileName;
-(instancetype)initWithDbName:(NSString*)fileName directory:(NSSearchPathDirectory)directory;

-(BOOL) deleteDatabase;
-(BOOL) executeQuery:(NSString*)query;
-(BOOL) executeQueryAsync:(NSString*)query resultHandler:(void(^)(NSArray*))handler;
-(NSArray*) executeQuerySync:(NSString*)query;

-(void) selectAllForTest:(NSString*)tableName;
@end

#endif
