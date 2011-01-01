//
//  MainViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Main View.
 
 Display list of possible actions with currently selected connection (based on RemoteConnector
 features).
 If no connection is configured yet the user is immediately redirected to the
 configuration screen.
 */
@interface MainViewController : UITabBarController <UITabBarControllerDelegate>
{
	IBOutlet UITabBar		*myTabBar; /*!< @brief Tab bar. */
	NSMutableArray	*menuList; /*!< @brief Item List. */
@private
	UIViewController *_currentController; /*!< @brief "Currently playing" Tab. */
	UIViewController *_bouquetController; /*!< @brief Bouquet List Tab. */
	UIViewController *_serviceController; /*!< @brief Service List Tab. */
	UIViewController *_timerController;  /*!< @brief Timer Tab. */
	UIViewController *_rcController;  /*!< @brief RC Emulator Tab. */
	UIViewController *_otherController;  /*!< @brief "Other" Tab. */
}

/*!
 @brief Table View.
 */
@property (nonatomic, retain) UITabBar *myTabBar;

@end
