//
//  BouquetListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"
#import "ServiceListController.h"
#import "ServiceSourceDelegate.h"

// Forward declaration
@class CXMLDocument;

/*!
 @brief Bouquet list.
 
 Display list of known bouquets and start ServiceListController on selected ones.
 */
@interface BouquetListController : ReloadableListController <UITableViewDelegate,
													UITableViewDataSource, ServiceSourceDelegate>
{
@private
	NSMutableArray *_bouquets; /*!< @brief Bouquet List. */
	id<ServiceListDelegate, NSCoding> _delegate; /*!< @brief Delegate. */
	BOOL _refreshBouquets; /*!< @brief Refresh Bouquet List on next open? */
	BOOL _isRadio; /*!< @brief Are we in radio mode? */
	BOOL _isSplit; /*!< @brief Split mode? */
	ServiceListController *_serviceListController; /*!< @brief Caches Service List instance. */
	UIBarButtonItem *_radioButton; /*!< @brief Radio/TV-mode toggle */

	CXMLDocument *_bouquetXMLDoc; /*!< @brief Bouquet XML. */
}

/*!
 @brief Set Service Selection Delegate.
 
 This Function is required for Timers as they will use the provided Callback when you change the
 Service of a Timer.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (id<ServiceListDelegate, NSCoding>) delegate;


/*!
 @brief Currently in radio mode?
 */
@property (nonatomic) BOOL isRadio;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Service List
 */
@property (nonatomic, retain) IBOutlet ServiceListController *serviceListController;

/*!
 @breif View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end
