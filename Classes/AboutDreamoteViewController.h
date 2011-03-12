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
	welcomeTypes welcomeType; /*!< @brief Welcome type. */
}

/*!
 @brief Init with welcome type.
 Use this initializer when opening this view as welcome screen.

 @param welcomeType Welcome type to use.
 @return AboutDreamoteViewController instance.
 */
- (id)initWithWelcomeType:(welcomeTypes)welcomeType;

@end
