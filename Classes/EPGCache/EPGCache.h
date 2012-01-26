//
//  EPGCache.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "EventSourceDelegate.h"
#import "ServiceSourceDelegate.h"
#import "ServiceProtocol.h"

// forward declare
@protocol EPGCacheDelegate;
@class SaxXmlReader;

/*!
 @brief Local EPGCache.
 
 Used for MultiEPG to minimize loading time.
 */
@interface EPGCache : NSObject <EventSourceDelegate, ServiceSourceDelegate>
{
@private
	NSString *_databasePath;
	NSObject<ServiceProtocol> *_service;
	BOOL _isRadio;
	NSObject<ServiceProtocol> *_bouquet;
	NSObject<EPGCacheDelegate> *_delegate;
	NSMutableArray *_serviceList;
	SaxXmlReader *_xmlReader;

	NSOperationQueue *queue; /*!< @brief Queue with pending event additions. */
	UIBackgroundTaskIdentifier _backgroundTask; /*!< @brief Identifier for current background task. */

	sqlite3 *database;
	sqlite3_stmt *insert_stmt;
}

/*!
 @brief Get singleton.
 */
+ (EPGCache *)sharedInstance;

/*!
 @brief Threadsafe version of addEvent

 @param event Event to add to cache.
 */
- (void)addEventOperation:(NSObject<EventProtocol> *)event;

/*!
 @brief Remove old events.
 */
- (void)cleanCache;

/*!
 @brief Refresh a bouquet.
 
 @param bouquet Bouquet to refresh the EPG for.
 @param delegate Delegate to call back.
 @param isRadio Fetching radio bouquet? Needed in Single bouquet mode.
 */
- (void)refreshBouquet:(NSObject<ServiceProtocol> *)bouquet delegate:(NSObject<EPGCacheDelegate> *)delegate isRadio:(BOOL)isRadio;

/*!
 @brief Read events for a given time interval and return them to a delegate.
 
 @param begin Start of timeframe
 @param end End of timeframe
 @param delegate Delegate for callbacks
 */
- (void)readEPGForTimeIntervalFrom:(NSDate *)begin until:(NSDate *)end to:(NSObject<EventSourceDelegate> *)delegate;

/*!
 @brief Get event following the one given in parameters.

 @param event Event used as base.
 @param service Service for this search.
 @return Next event on this service.
 */
- (NSObject<EventProtocol> *)getNextEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Get event preceding the one given in parameters.

 @param event Event used as base.
 @param service Service for this search.
 @return Preceding event on this service.
 */
- (NSObject<EventProtocol> *)getPreviousEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Start new transaction.
 Can be used e.g. to refresh the cache passively from the ServiceList.
 Call this method before starting the refresh, then call addEvent: for incoming events and
 finally stopTransaction to finish the transaction.
 
 @param service Service the incoming events will be assigned to. Can be nil if the events contain valid services.
 @return YES if the transaction was successfully started, else NO.
 */
- (BOOL)startTransaction:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Stop a previously started transaction.
 */
- (void)stopTransaction;

/*!
 @brief Perform search in EPG Cache.

 @param name Text to search in title.
 @param delegate Delegate for callbacks
 */
- (void)searchEPGForTitle:(NSString *)name delegate:(NSObject<EventSourceDelegate> *)delegate;



/*!
 @brief Is a bouquet currently being refreshed?
 */
@property (nonatomic, readonly) BOOL reloading;

@end



/*!
 @brief EPGCache delegate protocol.
 */
@protocol EPGCacheDelegate <ServiceSourceDelegate>
/*!
 @brief Cache was successfully refreshed.
 */
- (void)finishedRefreshingCache;

/*!
 @brief Inform delegate about number of remaining services to refresh.

 @param count Number of remaining services to refresh.
 */
- (void)remainingServicesToRefresh:(NSNumber *)count;
@end