//
//  AboutDreamoteViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"

@protocol AboutDreamoteDelegate;

/*!
 @brief About/Welcome view.
 
 Displays a webkit widget which renders the a html file bundled with this application.
 */
@interface AboutDreamoteViewController : UIViewController <UIWebViewDelegate,
														MFMailComposeViewControllerDelegate>
{
@private
	UIWebView *_aboutText; /*!< @brief Web view. */
	UIButton *_doneButton; /*!< @brief "Done" Button. */
	UIButton *_mailButton; /*!< @brief Mail button. */
	UIButton *_twitterButton; /*!< @brief "Follow us" button. */
	welcomeTypes welcomeType; /*!< @brief Welcome type. */
}

/*!
 @brief Init with welcome type.
 Use this initializer when opening this view as welcome screen.

 @param welcomeType Welcome type to use.
 @return AboutDreamoteViewController instance.
 */
- (id)initWithWelcomeType:(welcomeTypes)welcomeType;

/*!
 @brief Delegate.
 */
@property (nonatomic, unsafe_unretained) NSObject<AboutDreamoteDelegate> *aboutDelegate;

@end

/*!
 @brief Callbacks for About/Welcome view.
 */
@protocol AboutDreamoteDelegate
/*!
 @brief View was dismissed.
 */
- (void)dismissedAboutDialog;
@end