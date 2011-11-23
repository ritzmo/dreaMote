//
//  TimerListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/TimerProtocol.h>
#import "ReloadableListController.h"
#import "TimerSourceDelegate.h"
#import "TimerViewController.h" /* TimerViewDelegate */
#import "MBProgressHUD.h" /* MBProgressHUDDelegate */

#if INCLUDE_FEATURE(Ads)
#import "iAd/ADBannerView.h"
#endif

/*!
 @brief Timer List.
 
 Lists timers and allows to open a TimerViewController for further information / editing.
 Removing a timer is also allowed.
 
 @note The list is always reloaded when appearing to avoid problems with missing / wrong
 timer ids.
 */
@interface TimerListController : ReloadableListController <UITableViewDelegate,
#if INCLUDE_FEATURE(Ads)
													ADBannerViewDelegate,
#endif
													UITableViewDataSource,
													MBProgressHUDDelegate,
													TimerSourceDelegate,
													TimerViewDelegate>
{
@private
	NSMutableArray *_timers; /*!< @brief Timer List. */
	NSInteger _dist[kTimerStateMax]; /*!< @brief Offset of State in Timer List. */
	TimerViewController *_timerViewController; /*!< @brief Cached Timer Detail View. */
	BOOL _willReappear; /*!< @brief Used to guard free of ressources on close if we are opening a subview. */
	UIBarButtonItem *_cleanupButton; /*!< @brief Cleanup button. */
	NSMutableSet *_selected; /*!< @brief Selected Timer. */
	UIButton *_deleteButton; /*!< @brief Button used for Multi Delete. */

#if INCLUDE_FEATURE(Ads)
@private
	ADBannerView *_adBannerView;;
	BOOL _adBannerViewIsVisible;
#endif
}

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Timer View
 */
@property (nonatomic, strong) IBOutlet TimerViewController *timerViewController;

/*!
 @breif View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end
