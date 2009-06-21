//
//  BouquetListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declarations...
@class ServiceListController;
@class CXMLDocument;

/*!
 @brief Bouquet List.
 */
@interface BouquetListController : UIViewController <UIActionSheetDelegate,
													UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_bouquets; /*!< @brief Bouquet List. */
	SEL _selectCallback; /*!< @brief Callback Selector. */
	id _selectTarget; /*!< @brief Callback Object. */
	BOOL _refreshBouquets; /*!< @brief Refresh Bouquet List on next open? */
	ServiceListController *serviceListController; /*!< @brief Caches Service List instance. */

	CXMLDocument *bouquetXMLDoc; /*!< @brief Bouquet XML. */
}

/*!
 @brief Set Service Selection Callback.
 
 This Function is required for Timers as they will use this Callback when you change the
 Service of a Timer.
 
 @param target Callback object.
 @param action Callback selector.
 */
- (void)setTarget: (id)target action: (SEL)action;

@end
