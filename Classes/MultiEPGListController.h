//
//  MultiEPGListController.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ReloadableListController.h"

#import "EPGCache.h"
#import "EventSourceDelegate.h"
#import "MBProgressHUD.h" /* MBProgressHUDDelegate */
#import "ServiceSourceDelegate.h"

// forward declare
@class CXMLDocument;
@protocol MultiEPGDelegate;

/*!
 @brief MultiEPG Controller.
 Provides MultiEPG including all management Code.

 @todo Reconsider implementing this as a view, because this is pretty much what we use of it.
 */
@interface MultiEPGListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															EPGCacheDelegate,
															EventSourceDelegate,
															MBProgressHUDDelegate,
															SwipeTableViewDelegate,
															ServiceSourceDelegate>
{
@private
	BOOL _willReapper; /*!< @brief Not removed from stack. */
	EPGCache *_epgCache; /*!< @brief EPGCache Singleton. */
	NSObject<MultiEPGDelegate> *_mepgDelegate;
	NSObject<ServiceProtocol> *_bouquet; /*!< @brief Current Bouquet. */
	NSMutableArray *_services; /*!< @brief List of services. */
	CXMLDocument *_serviceXMLDocument; /*!< @brief Current Service XML-Document. */
	NSMutableDictionary *_events; /*!< @brief Dictionary (service sref) -> (event list). */
	NSDate *_curBegin; /*!< @brief Current begin of timespan. */
	MBProgressHUD *progressHUD; /*!< @brief Progress Hud. */
	NSInteger pendingRequests; /*!< @brief Pending requests. */
	NSTimer *_refreshTimer; /*!< @brief Timer used to refresh "_secondsSinceBegin". */
	NSTimeInterval _secondsSinceBegin; /*!< @brief Offset to "_curBegin". */
}

/*!
 @brief Bouquet.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *bouquet;

/*!
 @brief Current Begin.
 */
@property (nonatomic, retain) NSDate *curBegin;

/*!
 @brief MultiEPG Delegate.
 */
@property (nonatomic, retain) NSObject<MultiEPGDelegate> *multiEpgDelegate;

/*!
 @brief View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end



/*!
 @brief Delegate for MultiEPG List.
 */
@protocol MultiEPGDelegate
/*!
 @brief Event was selected in Multi EPG.
 A event has been selected, please note that for convenience reasons the event can be nil.
 This can be used to open e.g. the Event List instead, thereby fetching new events if none
 were known before.

 @param multiEPG MultiEPG the selection was made in.
 @param event Event selected.
 @param service Service event is on.
 */
- (void)multiEPG:(MultiEPGListController *)multiEPG didSelectEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service;
@end