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
 */
@interface AboutViewController : UIViewController <UIWebViewDelegate>
{
@private
	UIButton *doneButton; /*!< @brief "Done" Button. */
}

@end
