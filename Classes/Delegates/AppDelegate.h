//
//  AppDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief What type of welcome notification to show?
 */
typedef enum
{
	welcomeTypeNone, /*!< @brief None, this version was launched before. */
	welcomeTypeFull, /*!< @brief Full, first launch of dreaMote. */
	welcomeTypeChanges, /*!< @brief Only show (major) changes since last version. */
} welcomeTypes; 



/*!
 @brief Application Delegate.
 */
@interface AppDelegate : NSObject  <UIApplicationDelegate, UITabBarControllerDelegate,
									UIAlertViewDelegate>
{
@private
	BOOL wasSleeping; /*!< @brief Application was in background before. */
	UIWindow *window; /*!< @brief Application window. */
	UITabBarController *tabBarController; /*!< @brief Tab Bar Controller. */
	NSURL *cachedURL; /*!< @brief Cached URL request. */
	welcomeTypes welcomeType; /*!< @brief Type of welcome we're showing. */
}

/*!
 @brief Application window.
 */
@property (nonatomic, retain) IBOutlet UIWindow *window;

/*!
 @brief Tab Bar Controller.
 */
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

/*!
 @brief Currently busy?
 */
@property (nonatomic, readonly) BOOL isBusy;

/*!
 @brief Welcome type.
 For simplicity we show the welcome screen from our main view.

 @note Getter reset to welcomeTypeNone after first read.
 */
@property (nonatomic, readonly) welcomeTypes welcomeType;

@end
