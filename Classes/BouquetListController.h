//
//  BouquetListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ServiceListController.h"

// Forward declaration
@class CXMLDocument;

/*!
 @brief Bouquet list.
 
 Display list of known bouquets and start ServiceListController on selected ones.
 */
@interface BouquetListController : UIViewController <UIActionSheetDelegate,
													UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_bouquets; /*!< @brief Bouquet List. */
	id<ServiceListDelegate, NSCoding> _delegate; /*!< @brief Delegate. */
	BOOL _refreshBouquets; /*!< @brief Refresh Bouquet List on next open? */
	ServiceListController *_serviceListController; /*!< @brief Caches Service List instance. */

	CXMLDocument *_bouquetXMLDoc; /*!< @brief Bouquet XML. */
}

/*!
 @brief Set Service Selection Delegate.
 
 This Function is required for Timers as they will use the provided Callback when you change the
 Service of a Timer.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<ServiceListDelegate, NSCoding>) delegate;

@end
