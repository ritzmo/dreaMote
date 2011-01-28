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
#import "EventViewController.h"
#import "ServiceSourceDelegate.h"

// forward declare
@class CXMLDocument;

@interface MultiEPGListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															EPGCacheDelegate,
															EventSourceDelegate,
															ServiceSourceDelegate>
{
@private
	EPGCache *_epgCache; /*!< @brief EPGCache Singleton. */
	NSMutableArray *_services; /*!< @brief List of services. */
	CXMLDocument *_serviceXMLDocument; /*!< @brief Current Service XML-Document. */
	NSMutableDictionary *_events; /*!< @brief Dictionary (service sref) -> (event list). */
	NSDate *_curBegin; /*!< @brief Current begin of timespan. */

	EventViewController *_eventViewController; /*!< @brief Cached Event Detail View. */
}

@end
