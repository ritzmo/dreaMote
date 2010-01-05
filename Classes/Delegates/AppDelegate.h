//
//  AppDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Application Delegate.
 */
@interface AppDelegate : NSObject  <UIApplicationDelegate>
{
	UIWindow *window; /*!< @brief Application window. */
	UINavigationController *navigationController; /*!< @brief Navigation Controller. */
}

/*!
 @brief Application window.
 */
@property (nonatomic, retain) IBOutlet UIWindow *window;

/*!
 @brief Navigation Controller.
 */
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end
