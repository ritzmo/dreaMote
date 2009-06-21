//
//  ServiceListController.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declarations
@class EventListController;
@class CXMLDocument;
@protocol ServiceProtocol;

/*!
 @brief Service List.
 */
@interface ServiceListController : UIViewController <UIActionSheetDelegate,
													UITableViewDelegate, UITableViewDataSource>
{
@private
	NSObject<ServiceProtocol> *_bouquet; /*!< @brief Current Bouquet. */
	NSMutableArray *_services; /*!< @brief Service List. */
	SEL _selectCallback; /*!< @brief Callback Selector. */
	id _selectTarget; /*!< @brief Callback object. */
	BOOL _refreshServices; /*!< @brief Refresh Service List on next open? */
	EventListController *_eventListController; /*!< @brief Caches Event List View. */

	CXMLDocument *_serviceXMLDoc; /*!< Current Service XML Document. */
}

/*!
 @brief Set Service Selection Callback.
 
 This Function is required for Timers as they will use this Callback when you change the
 Service of a Timer.
 
 @param target Callback object.
 @param action Callback selector.
 */
- (void)setTarget: (id)target action: (SEL)action;



/*!
 @brief Bouquet.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *bouquet;

@end
