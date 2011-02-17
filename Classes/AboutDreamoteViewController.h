//
//  AboutDreamoteViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

/*!
 @brief About.
 
 Displays a webkit widget which renders the about.html bundled with this application.
 */
@interface AboutDreamoteViewController : UIViewController <UIWebViewDelegate,
														MFMailComposeViewControllerDelegate>
{
@private
	UIButton *_doneButton; /*!< @brief "Done" Button. */
	UIButton *_mailButton; /*!< @brief Mail button. */
}

@end
