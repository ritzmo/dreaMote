//
//  EPGCache.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGCache.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

#import "../Objects/Generic/Event.h"
#import "../Objects/Generic/Service.h"

static EPGCache *_sharedInstance = nil;

@implementation EPGCache

+ (EPGCache *)sharedInstance
{
	if(_sharedInstance == nil)
		_sharedInstance = [[EPGCache alloc] init];
	return _sharedInstance;
}

- (id)init
{
	if((self = [super init]))
	{
		_databasePath = [[kEPGCachePath stringByExpandingTildeInPath] retain];
	}
	return self;
}

- (void)dealloc
{
	[_bouquet release];
	[_databasePath release];
	[_service release];
	[_serviceList release];

	[super dealloc];
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (void)indicateError:(NSObject<DataSourceDelegate> *)delegate error:(NSError *)error
{
	// check if delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:error:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:errorParsing];
	if(delegate && [delegate respondsToSelector:errorParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&error atIndex:4];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)indicateSuccess:(NSObject<DataSourceDelegate> *)delegate
{
	// check if delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegate:finishedParsingDocument:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:finishedParsing];
	if(delegate && [delegate respondsToSelector:finishedParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:finishedParsing];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

/* ensure db exists */
-(void)checkDatabase
{
	// check if db already exists
	const NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath:_databasePath])
	{
		// does not exist, copy dummy
		NSString *dummyPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"epgcache.sqlite"];
		[fileManager copyItemAtPath:dummyPath toPath:_databasePath error:nil];
	}
}

- (void)fetchServices
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_currDocument release];
	_currDocument = [[[RemoteConnectorObject sharedRemoteConnector] fetchServices:self bouquet:_bouquet isRadio:_isRadio] retain];
	[pool release];
}

- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_service release];
	_service = [[_serviceList lastObject] retain];
	[_serviceList removeLastObject];

	[_currDocument release];
	_currDocument = [[[RemoteConnectorObject sharedRemoteConnector] fetchEPG:self service:_service] retain];
	[pool release];
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
#if 0
	// alert user
	// NOTE: die quietly for now, since otherwise we might spam
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];
#endif

	if([_serviceList count])
	{
		// continue fetching events
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	// indicate that we're done
	else
	{
		[self stopTransaction];
		[_delegate performSelectorOnMainThread:@selector(finishedRefreshingCache) withObject:nil waitUntilDone:NO];
	}
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	if([_serviceList count])
	{
		// start fetching events
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	// indicate that we're done
	else
	{
		[self stopTransaction];
		[_delegate performSelectorOnMainThread:@selector(finishedRefreshingCache) withObject:nil waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService:(NSObject <ServiceProtocol>*)service
{
	NSObject<ServiceProtocol> *copy = [service copy];
	[_serviceList addObject:copy];

	// delete existing entries for this bouquet
	const char *stmt = "DELETE FROM events WHERE sref = ?;";
	sqlite3_stmt *compiledStatement = NULL;
	if(sqlite3_prepare_v2(database, stmt, -1, &compiledStatement, NULL) == SQLITE_OK)
	{
		sqlite3_bind_text(compiledStatement, 1, [copy.sref UTF8String], -1, SQLITE_TRANSIENT);
		if(sqlite3_step(compiledStatement) != SQLITE_OK)
		{
			// TODO: do we want to handle this?
		}
	}
	sqlite3_finalize(compiledStatement);

	[copy release];
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent:(NSObject <EventProtocol>*)event
{
	// just to be sure, make synchronized…
	@synchronized(self)
	{
		sqlite3_bind_text(insert_stmt, 1, [event.eit UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_int64(insert_stmt, 2, [event.begin timeIntervalSince1970]);
		sqlite3_bind_int64(insert_stmt, 3, [event.end timeIntervalSince1970]);
		sqlite3_bind_text(insert_stmt, 4, [event.title UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(insert_stmt, 5, [event.sdescription UTF8String], -1, SQLITE_TRANSIENT);
		sqlite3_bind_text(insert_stmt, 6, [event.edescription UTF8String], -1, SQLITE_TRANSIENT);
		if(_service != nil)
			sqlite3_bind_text(insert_stmt, 7, [_service.sref UTF8String], -1, SQLITE_TRANSIENT);
		else
			sqlite3_bind_text(insert_stmt, 7, [event.service.sref UTF8String], -1, SQLITE_TRANSIENT);

		if(sqlite3_step(insert_stmt) != SQLITE_DONE)
		{
			// handle error
		}
		sqlite3_reset(insert_stmt);
	}
}

#pragma mark -
#pragma mark Externally visible
#pragma mark -

/* start new transaction */
- (BOOL)startTransaction:(NSObject<ServiceProtocol> *)service
{
	// cannot start transaction while one is already running
	if(database != NULL) return NO;

	BOOL retVal = YES;
	[self checkDatabase];
	_service = [service copy];

	retVal = (sqlite3_open([_databasePath UTF8String], &database) == SQLITE_OK);
	if(retVal)
	{
		const char *stmt = "INSERT INTO events (eit, begin, end, title, sdescription, edescription, sref) VALUES (?, ?, ?, ?, ?, ?, ?);";
		if(sqlite3_prepare_v2(database, stmt, -1, &insert_stmt, NULL) != SQLITE_OK)
		{
			sqlite3_close(database);
			database = NULL;
			retVal = NO;
		}
		else if(service != nil)
		{
			// delete existing entries for this bouquet
			const char *stmt = "DELETE FROM events WHERE sref = ?;";
			sqlite3_stmt *compiledStatement = NULL;
			if(sqlite3_prepare_v2(database, stmt, -1, &compiledStatement, NULL) == SQLITE_OK)
			{
				sqlite3_bind_text(compiledStatement, 1, [service.sref UTF8String], -1, SQLITE_TRANSIENT);
				if(sqlite3_step(compiledStatement) != SQLITE_OK)
				{
					// TODO: do we want to handle this?
				}
			}
			sqlite3_finalize(compiledStatement);
		}
	}
	return retVal;
}

/* stop current transaction */
- (void)stopTransaction
{
	if(database == NULL) return;

	[_service release];
	_service = nil;

	sqlite3_finalize(insert_stmt);
	insert_stmt = NULL;
	sqlite3_close(database);
	database = NULL;
}

/* start refreshing a bouquet */
- (void)refreshBouquet:(NSObject<ServiceProtocol> *)bouquet delegate:(NSObject<EPGCacheDelegate> *)delegate isRadio:(BOOL)isRadio
{
	if(![self startTransaction:nil])
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
															  message:NSLocalizedString(@"Could not open connection to database.", @"")
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		[alert release];

		[delegate performSelectorOnMainThread:@selector(finishedRefreshingCache) withObject:nil waitUntilDone:NO];
		return;
	}

	[_delegate release];
	_delegate = [delegate retain];
	[_bouquet release];
	_bouquet = [bouquet copy];

	// fetch list of services, followed by epg for each service
	[_serviceList release];
	_serviceList = [[NSMutableArray alloc] init];
	_isRadio = isRadio;
	[NSThread detachNewThreadSelector:@selector(fetchServices) toTarget:self withObject:nil];
}

/* read epg for given time interval */
- (void)readEPGForTimeIntervalFrom:(NSDate *)begin until:(NSDate *)end to:(NSObject<EventSourceDelegate> *)delegate
{
	sqlite3 *db = NULL;
	NSError *error = nil;
	[self checkDatabase];

	if(sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
	{
		const char *stmt = "SELECT * FROM events WHERE end >= ? AND begin <= ?;";
		sqlite3_stmt *compiledStatement = NULL;
		if(sqlite3_prepare_v2(db, stmt, -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			sqlite3_bind_int64(compiledStatement, 1, [begin timeIntervalSince1970]);
			sqlite3_bind_int64(compiledStatement, 2, [end timeIntervalSince1970]);
			while(sqlite3_step(compiledStatement) == SQLITE_ROW)
			{
				GenericEvent *event = [[GenericEvent alloc] init];
				GenericService *service = [[GenericService alloc] init];
				event.service = service;

				// read event data
				event.eit = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
				event.begin = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 1)];
				event.end = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 2)];
				event.title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
				event.sdescription = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 4)];
				event.edescription = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 5)];
				service.sref = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 6)];

				// send to delegate
				[delegate performSelectorOnMainThread:@selector(addEvent:) withObject:event waitUntilDone:NO];
				[service release];
				[event release];
			}
		}
		else
		{
			error = [NSError errorWithDomain:@"myDomain"
										code:110
									userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unable to compile SQL-Query.", @"") forKey:NSLocalizedDescriptionKey]];
		}

		sqlite3_finalize(compiledStatement);
	}
	else
	{
		error = [NSError errorWithDomain:@"myDomain"
									code:111
								userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unable to open database.", @"") forKey:NSLocalizedDescriptionKey]];
	}

	// handle error/success
	if(error)
	{
		[self indicateError:delegate error:error];
	}
	else
	{
		[self indicateSuccess:delegate];
	}

	sqlite3_close(db);
}

@end