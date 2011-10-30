//
//  EPGCache.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGCache.h"

#import <unistd.h>
#import "Constants.h"
#import "RemoteConnectorObject.h"

#import <Objects/Generic/Event.h>
#import <Objects/Generic/Service.h>

#import <XMLReader/BaseXMLReader.h>

#define kMaxRetries	10

#define AssignStringIfSet(column, target, obj) do {\
	char *target = (char *)sqlite3_column_text(compiledStatement, column);\
	if(target)\
		obj.target = [NSString stringWithUTF8String:target];\
	} while(0);

static EPGCache *_sharedInstance = nil;

@interface EPGCache()
/*!
 @brief Get event following or preceding the one given in parameters.

 @param event Event used as base.
 @param service Service for this search.
 @param next return next event if YES, else preceding.
 @return Event on this service matching search parameters.
 */
- (NSObject<EventProtocol> *)getEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service returnNext:(BOOL)next;
@end

@implementation EPGCache

+ (EPGCache *)sharedInstance
{
	static dispatch_once_t epgCacheSingletonToken;
	dispatch_once(&epgCacheSingletonToken, ^{
		_sharedInstance = [[EPGCache alloc] init];
	});
	return _sharedInstance;
}

- (id)init
{
	if((self = [super init]))
	{
		_databasePath = [kEPGCachePath stringByExpandingTildeInPath];
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1];
	}
	return self;
}

- (void)dealloc
{
	[queue cancelAllOperations];
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (void)indicateError:(NSObject<DataSourceDelegate> *)delegate error:(__unsafe_unretained NSError *)error
{
	// check if delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:errorParsing];
	if(delegate && [delegate respondsToSelector:errorParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&error atIndex:3];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)indicateSuccess:(NSObject<DataSourceDelegate> *)delegate
{
	// check if delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegateFinishedParsingDocument:);
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

/* search previous/next event */
- (NSObject<EventProtocol> *)getEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service returnNext:(BOOL)next
{
	sqlite3 *db = NULL;
	GenericEvent *newEvent = nil;
	[self checkDatabase];

	if(sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
	{
		char *stmt = NULL;
		if(next)
			stmt = "SELECT * FROM events WHERE begin > ? AND sref = ? ORDER BY begin ASC LIMIT 0,1;";
		else
			stmt = "SELECT * FROM events WHERE begin < ? AND sref = ? ORDER BY begin DESC LIMIT 0,1;";

		sqlite3_stmt *compiledStatement = NULL;
		if(sqlite3_prepare_v2(db, stmt, -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			sqlite3_bind_int64(compiledStatement, 1, [event.begin timeIntervalSince1970]);
			sqlite3_bind_text(compiledStatement, 2, [service.sref UTF8String], -1, SQLITE_TRANSIENT);
			if(sqlite3_step(compiledStatement) == SQLITE_ROW)
			{
				newEvent = [[GenericEvent alloc] init];
				newEvent.service = service;

				// read event data
				AssignStringIfSet(0, eit, newEvent)
				newEvent.begin = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 1)];
				newEvent.end = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 2)];
				AssignStringIfSet(3, title, newEvent)
				AssignStringIfSet(4, sdescription, newEvent)
				AssignStringIfSet(5, edescription, newEvent)
			}
		}
		sqlite3_finalize(compiledStatement);
	}
	sqlite3_close(db);

	return newEvent;
}

- (void)fetchServices
{
	@autoreleasepool {
		SafeRetainAssign(_xmlReader, [[RemoteConnectorObject sharedRemoteConnector] fetchServices:self bouquet:_bouquet isRadio:_isRadio]);
	}
}

- (void)fetchData
{
	@autoreleasepool {
		SafeRetainAssign(_service, [_serviceList lastObject]);
		[_serviceList removeLastObject];

		SafeRetainAssign(_xmlReader, [[RemoteConnectorObject sharedRemoteConnector] fetchEPG:self service:_service]);
	}
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error
{
#if 0
	// alert user
	// NOTE: die quietly for now, since otherwise we might spam
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];
#endif

	// rollback just to be safe
	sqlite3_exec(database, "ROLLBACK", 0, 0, 0);
	[self dataSourceDelegateFinishedParsingDocument:dataSource];
}

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	NSUInteger count = [_serviceList count];
	if(count)
	{
		// commit last bunch of updates and start a new transaction
		sqlite3_exec(database, "COMMIT", 0, 0, 0);
		sqlite3_exec(database, "BEGIN", 0, 0, 0);

		[_delegate performSelectorOnMainThread:@selector(remainingServicesToRefresh:) withObject:[NSNumber numberWithUnsignedInteger:count] waitUntilDone:NO];
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
		if(sqlite3_step(compiledStatement) != SQLITE_DONE)
		{
#if IS_DEBUG()
			const int errcode = sqlite3_errcode(database);
			if(errcode == SQLITE_NOMEM)
			{
				NSLog(@"sqlite3 ran out of memory while deleting past events, ignoring");
			}
			else
			{
				sqlite3_finalize(compiledStatement);
				compiledStatement = NULL;
				[NSException raise:@"FailedToClearEpgCache" format:@"failed to clear epg cache for service %@ (%@) due to error %s (%d: %d)", service.sname, service.sref, sqlite3_errmsg(database), errcode, sqlite3_extended_errcode(database)];
			}
#else
			// ignore
#endif
		}
	}
	sqlite3_finalize(compiledStatement);

}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent:(NSObject<EventProtocol> *)event
{
	if(insert_stmt == NULL) return;

	sqlite3_reset(insert_stmt);
	sqlite3_bind_text(insert_stmt, 1, [event.eit UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int64(insert_stmt, 2, [event.begin timeIntervalSince1970]);
	sqlite3_bind_int64(insert_stmt, 3, [event.end timeIntervalSince1970]);
	sqlite3_bind_text(insert_stmt, 4, [event.title UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_stmt, 5, [event.sdescription UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_stmt, 6, [event.edescription UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_stmt, 7, [_service.sref UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_stmt, 8, [_service.sname UTF8String], -1, SQLITE_TRANSIENT);

	if(sqlite3_step(insert_stmt) != SQLITE_DONE)
	{
#if IS_DEBUG()
		[NSException raise:@"FailedAddToEpgCache" format:@"failed to add event %@ (%.f on %@) to epg cache due to error %s (%d: %d)", event.title, [event.begin timeIntervalSince1970], _service.sname, sqlite3_errmsg(database), sqlite3_errcode(database), sqlite3_extended_errcode(database)];
#else
		// ignore
#endif
	}
}

#pragma mark -
#pragma mark Externally visible
#pragma mark -

/* threadsafe wrapper of addEvent */
- (void)addEventOperation:(NSObject<EventProtocol> *)event
{
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addEvent:) object:event];
	[queue addOperation:operation];
}

/* start new transaction */
- (BOOL)startTransaction:(NSObject<ServiceProtocol> *)service
{
	// cannot start transaction while one is already running
	if(database != NULL)
	{
#if IS_DEBUG()
		NSLog(@"[EPGCache] There already is a transcation active for service %@. Can't start transaction for service %@", _service.sname, service.sname);
#endif
		return NO;
	}

	BOOL retVal = YES;
	[self checkDatabase];
	_service = [service copy];

	retVal = (sqlite3_open([_databasePath UTF8String], &database) == SQLITE_OK);
	if(retVal)
	{
		const char *stmt = "INSERT INTO events (eit, begin, end, title, sdescription, edescription, sref, sname) VALUES (?, ?, ?, ?, ?, ?, ?, ?);";
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
				if(sqlite3_step(compiledStatement) != SQLITE_DONE)
				{
#if IS_DEBUG()
					const int errcode = sqlite3_errcode(database);
					if(errcode == SQLITE_NOMEM)
					{
						NSLog(@"sqlite3 ran out of memory while deleting past events, ignoring");
					}
					else
					{
						sqlite3_finalize(insert_stmt);
						sqlite3_close(database);
						insert_stmt = NULL;
						database = NULL;
						[NSException raise:@"FailedToClearEpgCache" format:@"failed to clear epg cache for service %@ (%@) due to error %s (%d: %d)", _service.sname, _service.sref, sqlite3_errmsg(database), errcode, sqlite3_extended_errcode(database)];
					}
#else
					// ignore
#endif
				}
			}
			sqlite3_finalize(compiledStatement);
		}

		// start transcation
		sqlite3_exec(database, "BEGIN", 0, 0, 0);
	}
	return retVal;
}

/* stop current transaction */
- (void)stopTransaction
{
	if(database == NULL) return;

	@synchronized(self)
	{
		[queue cancelAllOperations];
		SafeRetainAssign(_service, nil);

		// stop transcation
		sqlite3_exec(database, "COMMIT", 0, 0, 0);

		sqlite3_finalize(insert_stmt);
		insert_stmt = NULL;
		sqlite3_close(database);
		database = NULL;
	}
}

/* start refreshing a bouquet */
- (void)refreshBouquet:(NSObject<ServiceProtocol> *)bouquet delegate:(NSObject<EPGCacheDelegate> *)delegate isRadio:(BOOL)isRadio
{
	if(![self startTransaction:nil])
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
															  message:NSLocalizedString(@"Could not open connection to database.", @"")
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];

		[delegate performSelectorOnMainThread:@selector(finishedRefreshingCache) withObject:nil waitUntilDone:NO];
		return;
	}

	SafeRetainAssign(_delegate, delegate);
	SafeCopyAssign(_bouquet, bouquet);

	// fetch list of services, followed by epg for each service
	SafeRetainAssign(_serviceList, nil);
	_serviceList = [[NSMutableArray alloc] init];
	_isRadio = isRadio;
	[NSThread detachNewThreadSelector:@selector(fetchServices) toTarget:self withObject:nil];
}

/* remove old events from cache */
- (void)cleanCache
{
	sqlite3 *db = NULL;
	[self checkDatabase];

	if(sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
	{
		const char *stmt = "DELETE FROM events WHERE end <= ?;";
		sqlite3_stmt *compiledStatement = NULL;
		if(sqlite3_prepare_v2(db, stmt, -1, &compiledStatement, NULL) == SQLITE_OK)
		{
			// TODO: make interval configurable? previous events could be interesting.
			NSDate *now = [NSDate date];
			sqlite3_bind_int64(compiledStatement, 1, [now timeIntervalSince1970]);
			sqlite3_step(compiledStatement); // ignore error
		}
		sqlite3_finalize(compiledStatement);
	}

	sqlite3_close(db);
}

/* read epg for given time interval */
- (void)readEPGForTimeIntervalFrom:(NSDate *)begin until:(NSDate *)end to:(NSObject<EventSourceDelegate> *)delegate
{
	if(!begin || !end || !delegate)
	{
#if IS_DEBUG()
		if(!begin)
			[NSException raise:NSInvalidArgumentException format:@"begin was nil"];
		if(!end)
			[NSException raise:NSInvalidArgumentException format:@"end was nil"];
		if(!delegate)
			[NSException raise:NSInvalidArgumentException format:@"delegate was nil"];
#endif
		return;
	}

	sqlite3 *db = NULL;
	NSError *error = nil;
	[self checkDatabase];

	if(sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
	{
		const char *stmt = "SELECT * FROM events WHERE end >= ? AND begin <= ? ORDER BY begin ASC;";
		sqlite3_stmt *compiledStatement = NULL;
		int rc = SQLITE_BUSY;
		NSInteger retries = 0;
		do
		{
			int rc = sqlite3_prepare_v2(db, stmt, -1, &compiledStatement, NULL);

			/* database busy and still retries */
			if(rc == SQLITE_BUSY && retries < kMaxRetries)
			{
				usleep(200);
				++retries;
			}
			/* database free */
			else if(rc == SQLITE_OK)
			{
				sqlite3_bind_int64(compiledStatement, 1, [begin timeIntervalSince1970]);
				sqlite3_bind_int64(compiledStatement, 2, [end timeIntervalSince1970]);
				while(sqlite3_step(compiledStatement) == SQLITE_ROW)
				{
					GenericEvent *event = [[GenericEvent alloc] init];
					GenericService *service = [[GenericService alloc] init];
					event.service = service;

					// read event data
					AssignStringIfSet(0, eit, event)
					event.begin = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 1)];
					event.end = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 2)];
					AssignStringIfSet(3, title, event)
					AssignStringIfSet(4, sdescription, event)
					AssignStringIfSet(5, edescription, event)
					AssignStringIfSet(6, sref, service)

					// send to delegate
					[delegate performSelectorOnMainThread:@selector(addEvent:) withObject:event waitUntilDone:NO];
				}
				break; // XXX: why do I need to do this?
			}
			/* unhandled error or kMaxRetries hit */
			else
			{
				error = [NSError errorWithDomain:@"myDomain"
											code:110
										userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Unable to compile SQL-Query (Error-Code %d).", @""), rc] forKey:NSLocalizedDescriptionKey]];
				break;
			}
		} while(rc == SQLITE_BUSY);

		sqlite3_finalize(compiledStatement);
	}
	else
	{
		error = [NSError errorWithDomain:@"myDomain"
									code:111
								userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not open connection to database.", @"") forKey:NSLocalizedDescriptionKey]];
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

- (NSObject<EventProtocol> *)getNextEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service
{
	return [self getEvent:event onService:service returnNext:YES];
}

- (NSObject<EventProtocol> *)getPreviousEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service
{
	return [self getEvent:event onService:service returnNext:NO];
}

/* perform simple epg search */
- (void)searchEPGForTitle:(NSString *)name delegate:(NSObject<EventSourceDelegate> *)delegate
{
	sqlite3 *db = NULL;
	NSError *error = nil;
	[self checkDatabase];

	if(sqlite3_open([_databasePath UTF8String], &db) == SQLITE_OK)
	{
		const char *stmt = "SELECT * FROM events WHERE title LIKE ? ORDER BY begin ASC;";
		sqlite3_stmt *compiledStatement = NULL;
		int rc = SQLITE_BUSY;
		NSInteger retries = 0;
		do
		{
			int rc = sqlite3_prepare_v2(db, stmt, -1, &compiledStatement, NULL);

			/* database busy and still retries */
			if(rc == SQLITE_BUSY && retries < kMaxRetries)
			{
				usleep(200);
				++retries;
			}
			/* database free */
			else if(rc == SQLITE_OK)
			{
				NSString *searchString = [[NSString alloc ] initWithFormat:@"%%%@%%", name];
				sqlite3_bind_text(compiledStatement, 1, [searchString UTF8String], -1, SQLITE_TRANSIENT);
				while(sqlite3_step(compiledStatement) == SQLITE_ROW)
				{
					GenericEvent *event = [[GenericEvent alloc] init];
					GenericService *service = [[GenericService alloc] init];
					event.service = service;

					// read event data
					AssignStringIfSet(0, eit, event)
					event.begin = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 1)];
					event.end = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(compiledStatement, 2)];
					AssignStringIfSet(3, title, event)
					AssignStringIfSet(4, sdescription, event)
					AssignStringIfSet(5, edescription, event)
					AssignStringIfSet(6, sref, service)
					AssignStringIfSet(7, sname, service)

					// send to delegate
					[delegate performSelectorOnMainThread:@selector(addEvent:) withObject:event waitUntilDone:NO];
				}
				break; // XXX: why do I need to do this?
			}
			/* unhandled error or kMaxRetries hit */
			else
			{
				error = [NSError errorWithDomain:@"myDomain"
											code:110
										userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Unable to compile SQL-Query (Error-Code %d).", @""), rc] forKey:NSLocalizedDescriptionKey]];
				break;
			}
		} while(rc == SQLITE_BUSY);

		sqlite3_finalize(compiledStatement);
	}
	else
	{
		error = [NSError errorWithDomain:@"myDomain"
									code:111
								userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Could not open connection to database.", @"") forKey:NSLocalizedDescriptionKey]];
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
