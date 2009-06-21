//
//  EventListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declarations...
@protocol ServiceProtocol;
@class FuzzyDateFormatter;
@class EventViewController;
@class CXMLDocument;

/*!
 @brief Event List.
 
 Lists events and opens an EventViewController upon selection.
 */
@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@protected
	NSMutableArray *_events; /*!< @brief Event List. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Current Service. */
	FuzzyDateFormatter *dateFormatter; /*!< @brief Date Formatter. */

	CXMLDocument *eventXMLDoc; /*!< @brief Event XML Document. */
	EventViewController *eventViewController; /*!< @brief Cached Event Detail View. */
}

/*!
 @brief Open new Event List for given Service.
 
 @param ourService Service to display Events for.
 @return EventListController instance.
 */
+ (EventListController*)forService: (NSObject<ServiceProtocol> *)ourService;

/*!
 @brief Add Event to List.

 Used for < RemoteConnector >::fetchEPG Callback.
 
 @param event Event instance.
 */
- (void)addEvent:(id)event;



/*!
 @brief Service.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
