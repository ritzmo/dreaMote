//
//  AboutViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief About.
 
 Displays a webkit widget which renders the about.html bundled with this application.
 */
@interface AboutViewController : UIViewController <UIWebViewDelegate>
{
@private
	UIButton *_doneButton; /*!< @brief "Done" Button. */
}

@end
