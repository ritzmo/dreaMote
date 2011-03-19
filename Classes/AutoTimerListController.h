//
//  AutoTimerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ReloadableListController.h"
#import "AutoTimerSourceDelegate.h"

@class AutoTimerViewController;

/*!
 @brief AutoTimer List.
 */
@interface AutoTimerListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															AutoTimerSourceDelegate>
{
@private
	NSMutableArray *_autotimers; /*!< @brief AutoTimer List. */
	CXMLDocument *_curDocument; /*!< @brief Current XML Document. */
	BOOL _refreshAutotimers; /*!< @brief Refresh on next viewWillAppear? */
	BOOL _isSplit; /*!< @brief Split mode? */
	AutoTimerViewController *_autotimerView; /*!< @brief AutoTimer View. */
}

/*!
 @brief AutoTimer View.
 @note Should only be set explicitly if in split mode.
 */
@property (retain) AutoTimerViewController *autotimerView;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end
