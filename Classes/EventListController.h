//
//  EventListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EventSourceDelegate.h"
#import "EGORefreshTableHeaderView.h"

// Forward declarations...
@protocol ServiceProtocol;
@class FuzzyDateFormatter;
@class EventViewController;
@class CXMLDocument;

/*!
 @brief Event List.
 
 Lists events and opens an EventViewController upon selection.
 */
@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													EventSourceDelegate,
													EGORefreshTableHeaderDelegate,
													UIScrollViewDelegate>
{
@protected
	NSMutableArray *_events; /*!< @brief Event List. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Current Service. */
	FuzzyDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */

	CXMLDocument *_eventXMLDoc; /*!< @brief Event XML Document. */
	EventViewController *_eventViewController; /*!< @brief Cached Event Detail View. */
	EGORefreshTableHeaderView *_refreshHeaderView; /*!< @brief "Pull up to refresh". */
}

/*!
 @brief Open new Event List for given Service.
 
 @param ourService Service to display Events for.
 @return EventListController instance.
 */
+ (EventListController*)forService: (NSObject<ServiceProtocol> *)ourService;



/*!
 @brief Service.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
