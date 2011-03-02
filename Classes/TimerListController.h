//
//  TimerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/TimerProtocol.h"
#import "ReloadableListController.h"
#import "TimerSourceDelegate.h"
#import "TimerViewController.h" /* TimerViewDelegate */

#if IS_LITE()
#import "iAd/ADBannerView.h"
#endif

// Forward Declarations...
@class CXMLDocument;

/*!
 @brief Timer List.
 
 Lists timers and allows to open a TimerViewController for further information / editing.
 Removing a timer is also allowed.
 
 @note The list is always reloaded when appearing to avoid problems with missing / wrong
 timer ids.
 */
@interface TimerListController : ReloadableListController <UITableViewDelegate,
#if IS_LITE()
													ADBannerViewDelegate,
#endif
													UITableViewDataSource,
													TimerSourceDelegate,
													TimerViewDelegate>
{
@private
	NSMutableArray *_timers; /*!< @brief Timer List. */
	NSInteger _dist[kTimerStateMax]; /*!< @brief Offset of State in Timer List. */
	NSDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
	TimerViewController *_timerViewController; /*!< @brief Cached Timer Detail View. */
	BOOL _willReappear; /*!< @brief Used to guard free of ressources on close if we are opening a subview. */
	BOOL _isSplit; /*!< @brief Split mode? */

	CXMLDocument *_timerXMLDoc; /*!< @brief Current Timer XML Document. */
#if IS_LITE()
@private
	id _adBannerView;
	BOOL _adBannerViewIsVisible;
#endif
}

/*!
 @brief Timer List.
 */
@property (nonatomic, retain) NSMutableArray *timers;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Timer View
 */
@property (nonatomic, retain) IBOutlet TimerViewController *timerViewController;

/*!
 @breif View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end
