//
//  CurrentViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"
#import "Objects/ServiceProtocol.h"
#import "EventSourceDelegate.h"
#import "ServiceSourceDelegate.h"

// Forward declarations...
@class CXMLDocument;
@class FuzzyDateFormatter;

/*!
 @brief Current View.
 
 Displays the currently playing service and - if present - the current and next event.
 */
@interface CurrentViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													EventSourceDelegate, ServiceSourceDelegate>
{
@private
	NSObject<EventProtocol> *_now; /*!< @brief Currently playing event. */
	NSObject<EventProtocol> *_next; /*!< @brief Next event. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Current Service. */
	UITextView *_nowSummary; /*!< @brief Summary of current event. */
	UITextView *_nextSummary; /*!< @brief Summary of next event. */

	FuzzyDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
	CXMLDocument *_currentXMLDoc; /*!< @brief Current XML Document. */
}

@end
