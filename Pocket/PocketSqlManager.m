//
//  PocketSqlManager.m
//  Pocket
//
//  Created by VIEWPOINT on 2015. 3. 29..
//  Copyright (c) 2015년 VIEWPOINT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PocketSqlManager.h"
#import "PocketConst.h"
#import <sqlite3.h>

#pragma mark - NSString extensions
@interface NSString(PocketBase)
-(BOOL) isSame:(NSString*)str;
@end

@implementation NSString(PocketBase)
-(BOOL) isSame:(NSString*)str { return [self caseInsensitiveCompare:str] == NSOrderedSame; }
@end

#pragma - PocketSqlManager global variables
static PocketSqlManager* gManager = nil;

#pragma mark - PocketSqlManager private interface
@interface PocketSqlManager ()
-(instancetype)initWithDbName:(NSString*)fileName directory:(NSSearchPathDirectory)directory;
@end

#pragma mark - PocketSqlManager implementation
@implementation PocketSqlManager
{
@private
	sqlite3* _database;
	NSString* _dbPath;
	NSString* _fileName;
	NSSearchPathDirectory _directory;
}

-(instancetype)init
{
	[NSException raise:NSInternalInconsistencyException format:@"PocketSqlManager doesn't be implemented init method!!"];
	return nil;
}

+(instancetype)manager
{
	return gManager;
}

+(void)initializeWithDbName:(NSString*)fileName;
{
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		gManager = [[PocketSqlManager alloc] initWithDbName:fileName directory:NSCachesDirectory];
	});
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

-(BOOL) executeQueryAsync:(NSString*)query resultHandler:(void(^)(NSArray*))handler
{
	NSLog(@"Async query : %@", query);
	sqlite3_stmt* stmt;
	if(sqlite3_open([_dbPath UTF8String], &_database) == SQLITE_OK)
	{
		@try
		{
			NSMutableArray* result = [NSMutableArray new];
			NSMutableDictionary* columnNames = [NSMutableDictionary new];
			
			sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
			
			int count = sqlite3_column_count(stmt);
			NSMutableArray* types = [NSMutableArray new];
			for (int i = 0; i < count; i++)
				[types addObject:[NSString stringWithUTF8String:sqlite3_column_decltype(stmt, i)]];
			while(sqlite3_step(stmt) == SQLITE_ROW)
			{
				NSMutableDictionary* el = [NSMutableDictionary new];
				for (int i = 0; i < count; i++)
				{
					if([columnNames objectForKey:@(i)] == nil)
						[columnNames setObject:[NSString stringWithUTF8String:sqlite3_column_name(stmt, i)] forKey:@(i)];
					
					NSString* type = [types objectAtIndex:i];
					if([type isSame:kInteger])
						[el setObject:@(sqlite3_column_int(stmt, i)) forKey:[columnNames objectForKey:@(i)]];
					else if([type isSame:kReal])
						[el setObject:@(sqlite3_column_double(stmt, i)) forKey:[columnNames objectForKey:@(i)]];
					else if([type isSame:kText])
						[el setObject:@((char*)sqlite3_column_text(stmt, i)) forKey:[columnNames objectForKey:@(i)]];
				}
				[result addObject:el];
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

/**
 Return : Array of NSDictionary(column name, value)
 */
-(NSArray*) executeQuerySync:(NSString*)query
{
	NSLog(@"Sync query : %@", query);
	sqlite3_stmt* stmt;
	if(sqlite3_open([_dbPath UTF8String], &_database) == SQLITE_OK)
	{
		@try
		{
			NSMutableArray* result = [NSMutableArray new];
			NSMutableDictionary* columnNames = [NSMutableDictionary new];
			
			sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
			
			int count = sqlite3_column_count(stmt);
			NSMutableArray* types = [NSMutableArray new];
			for (int i = 0; i < count; i++)
				[types addObject:[NSString stringWithUTF8String:sqlite3_column_decltype(stmt, i)]];
			while(sqlite3_step(stmt) == SQLITE_ROW)
			{
				NSMutableDictionary* el = [NSMutableDictionary new];
				for (int i = 0; i < count; i++)
				{
					if([columnNames objectForKey:@(i)] == nil)
						[columnNames setObject:[NSString stringWithUTF8String:sqlite3_column_name(stmt, i)] forKey:@(i)];
					
					NSString* type = [types objectAtIndex:i];
					if([type isSame:kInteger])
						[el setObject:@(sqlite3_column_int(stmt, i)) forKey:[columnNames objectForKey:@(i)]];
					else if([type isSame:kReal])
						[el setObject:@(sqlite3_column_double(stmt, i)) forKey:[columnNames objectForKey:@(i)]];
					else if([type isSame:kText])
						[el setObject:@((char*)sqlite3_column_text(stmt, i)) forKey:[columnNames objectForKey:@(i)]];
				}
				[result addObject:el];
			}
			return result;
		}
		@finally
		{
			sqlite3_finalize(stmt);
			sqlite3_close(_database);
		}
	}
	return nil;
}

-(void) selectAllForTest:(NSString*)tableName
{
	NSString* query = [NSString stringWithFormat:@"select * from %@", tableName];
	sqlite3_stmt* stmt;
	if(sqlite3_open([_dbPath UTF8String], &_database) == SQLITE_OK)
	{
		@try
		{
			sqlite3_prepare_v2(_database, [query UTF8String], -1, &stmt, NULL);
			
			int count = sqlite3_column_count(stmt);
			NSMutableArray* types = [NSMutableArray new];
			for (int i = 0; i < count; i++)
				[types addObject:[NSString stringWithUTF8String:sqlite3_column_decltype(stmt, i)]];
			
			int rowNum = 0;
			while(sqlite3_step(stmt) == SQLITE_ROW)
			{
				NSMutableString* row = [NSMutableString new];
				for (int i = 0; i < count; i++)
				{
					if(i > 0)
						[row appendFormat:@","];
					
					[row appendFormat:@"[%@][", [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)]];
					
					NSString* type = [types objectAtIndex:i];
					if([type isSame:kInteger])
						[row appendFormat:@"%@", [NSNumber numberWithInt:sqlite3_column_int(stmt, i)]];
					else if([type isSame:kReal])
						[row appendFormat:@"%@", [NSNumber numberWithDouble:sqlite3_column_int(stmt, i)]];
					else if([type isSame:kText])
						[row appendFormat:@"%@", [NSString stringWithUTF8String:(char*)sqlite3_column_text(stmt, i)]];
					[row appendFormat:@"]"];
				}
				NSLog(@"%@[%d] : %@", tableName, rowNum++, row);
			}
		}
		@finally
		{
			sqlite3_finalize(stmt);
			sqlite3_close(_database);
		}
	}
}

@end