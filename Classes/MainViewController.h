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
@interface MainViewController : UITabBarController
{
	IBOutlet UITabBar		*myTabBar; /*!< @brief Tab bar. */
	NSMutableArray	*menuList; /*!< @brief Item List. */
@private
	UIViewController *_currentController;
	UIViewController *_bouquetController;
	UIViewController *_serviceController;
	UIViewController *_timerController;
	UIViewController *_rcController;
	UIViewController *_otherController;
}

/*!
 @brief Table View.
 */
@property (nonatomic, retain) UITabBar *myTabBar;

@end
