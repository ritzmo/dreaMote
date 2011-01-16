//
//  EventViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"
#import "Objects/ServiceProtocol.h"
#import "EventSourceDelegate.h"

// Forward declarations...
@class CXMLDocument;

/*!
 @brief Event View.
 
 Display further information of an Event and offer to program a timer for this event.
 */
@interface EventViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													EventSourceDelegate>
{
@private
	NSMutableArray *_similarEvents; /*!< @brief List of similar Events. */
	NSObject<EventProtocol> *_event; /*!< @brief Associated Events. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Current Service. */
	UITextView *_summaryView; /*!< @brief Summary of current event. */
	BOOL _similarFetched; /*!< @brief List of similar Events was already fetched. */
	BOOL _isSearch; /*!< @brief This View was opened from an EPG Search. */

	NSDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
	CXMLDocument *_eventXMLDoc; /*!< @brief Current Event XML Document. */
}

/*!
 @brief Open new EventViewController for given Event and Service.
 
 @param newEvent Event to open View for.
 @param newService Service of given Event.
 @return EventViewController instance.
 */
+ (EventViewController *)withEventAndService: (NSObject<EventProtocol> *) newEvent: (NSObject<ServiceProtocol> *)newService;

/*!
 @brief Open new EventViewController for given Event.
 
 @param newEvent Event to open View for.
 @return EventViewController instance.
 */
+ (EventViewController *)withEvent: (NSObject<EventProtocol> *) newEvent;



/*!
 @brief Event.
 */
@property (nonatomic, retain) NSObject<EventProtocol> *event;

/*!
 @brief Service.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

/*!
 @brief Result of an EPG Search?
 */
@property (nonatomic) BOOL search;

@end
