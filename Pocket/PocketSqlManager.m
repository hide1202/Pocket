//
//  PocketSqlManager.m
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 29..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PocketSqlManager.h"
#import <sqlite3.h>

#pragma mark - NSString extensions
@interface NSString(PocketBase)
-(BOOL) isSame:(NSString*)str;
@end

@implementation NSString(PocketBase)
-(BOOL) isSame:(NSString*)str { return [self caseInsensitiveCompare:str] == NSOrderedSame; }
@end

#pragma mark - PocketBase implementation
@implementation PocketSqlManager
{
@private
	sqlite3* _database;
	NSString* _dbPath;
	NSString* _fileName;
	NSSearchPathDirectory _directory;
}

-(instancetype)initWithDbName:(NSString*)fileName
{
	return [self initWithDbName:fileName directory:NSCachesDirectory];
}

-(instancetype)initWithDbName:(NSString*)fileName directory:(NSSearchPathDirectory)directory
{
	self = [super init];
	
	if(self)
	{
		_directory = directory;
		_fileName = fileName;
		
		NSString *docsDir = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES)[0];
		_dbPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent: fileName]];
		
		NSFileManager *filemgr = [NSFileManager defaultManager];
		if ([filemgr fileExistsAtPath:_dbPath ] == NO)
		{
			if (sqlite3_open([_dbPath UTF8String], &_database) == SQLITE_OK)
				sqlite3_close(_database);
			else
				[NSException raise:@"PocketException" format:@"%@", [NSString stringWithUTF8String:sqlite3_errmsg(_database)]];
		}
	}
	
	return self;
}

-(BOOL) deleteDatabase
{
	NSFileManager *filemgr = [NSFileManager defaultManager];
	if ([filemgr fileExistsAtPath:_dbPath ] == YES)
		return [filemgr removeItemAtPath:_dbPath error:nil];
	
	return NO;
}

-(BOOL) executeQuery:(NSString*)query
{
	sqlite3_stmt* stmt;
	if(sqlite3_open([_dbPath UTF8String], &_database) == SQLITE_OK)
	{
		@try
		{
			sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
			if(sqlite3_step(stmt) == SQLITE_DONE)
				return YES;
		}
		@finally
		{
			sqlite3_finalize(stmt);
			sqlite3_close(_database);
		}
	}
	return NO;
}

-(BOOL) executeQuery:(NSString*)query resultHandler:(void(^)(NSArray*))handler
{
	sqlite3_stmt* stmt;
	if(sqlite3_open([_dbPath UTF8String], &_database) == SQLITE_OK)
	{
		@try
		{
			sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
			NSMutableArray* result = [NSMutableArray new];
			
			int count = sqlite3_column_count(stmt);
			NSMutableArray* types = [NSMutableArray new];
			for (int i = 0; i < count; i++)
				[types addObject:[NSString stringWithUTF8String:sqlite3_column_decltype(stmt, i)]];
			while(sqlite3_step(stmt) == SQLITE_ROW)
			{
				for (int i = 0; i < count; i++)
				{
					NSString* type = [types objectAtIndex:i];
					if([type isSame:kInteger])
						[result addObject:[NSNumber numberWithInt:sqlite3_column_int(stmt, i)]];
					else if([type isSame:kReal])
						[result addObject:[NSNumber numberWithDouble:sqlite3_column_double(stmt, i)]];
					else if([type isSame:kText])
						[result addObject:[NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, i)]];
				}
			}
			
			handler(result);
		}
		@finally
		{
			sqlite3_finalize(stmt);
			sqlite3_close(_database);
		}
	}
	return NO;
}
@end