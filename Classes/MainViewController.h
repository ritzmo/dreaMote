//
//  MainViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#if IS_LITE()
#import "iAd/ADBannerView.h"
#endif

@class OtherListController;

/*!
 @brief Main View.
 
 Display list of possible actions with currently selected connection (based on RemoteConnector
 features).
 If no connection is configured yet the user is immediately redirected to the
 configuration screen.
 */
@interface MainViewController : UITabBarController <UITabBarControllerDelegate
#if IS_LITE()
													, ADBannerViewDelegate
#endif
													>
{
	IBOutlet UITabBar *myTabBar; /*!< @brief Tab bar. */
	NSMutableArray *menuList; /*!< @brief Item List. */
@private
	UIViewController *_bouquetController; /*!< @brief Bouquet List Tab. */
	UIViewController *_currentController; /*!< @brief "Currently playing" Tab. */
	UIViewController *_mediaplayerController; /*!< @brief "MediaPlayer" Tab on iPad. */
	UIViewController *_movieController; /*!< @brief "Movies" Tab on iPad. */
	OtherListController *_otherController;  /*!< @brief "Other" Tab. */
	UIViewController *_rcController;  /*!< @brief RC Emulator Tab. */
	UIViewController *_serviceController; /*!< @brief Service List Tab. */
	UIViewController *_timerController;  /*!< @brief Timer Tab. */
#if IS_LITE()
	id _adBannerView;
	BOOL _adBannerViewIsVisible;	
#endif
}

/*!
 @brief Table View.
 */
@property (nonatomic, retain) UITabBar *myTabBar;

@end
