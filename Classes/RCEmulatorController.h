//
//  RCEmulatorController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCEmulatorController : UIViewController <UIScrollViewDelegate>
{
@private
	BOOL _shouldVibrate;
	BOOL _fullRc;

	UIView *fullRcView;
	UIView *simpleRcView;
	UIView *screenView;
	UIScrollView *scrollView;
	UIImageView *imageView;
	UIToolbar *toolbar;
	UIBarButtonItem *screenshotButton;

	NSInteger _screenshotType;
}

@end
