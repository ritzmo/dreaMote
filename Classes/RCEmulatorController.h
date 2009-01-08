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

	UIView *screenView;
	UIScrollView *scrollView;
	UIImageView *imageView;
	UIToolbar *toolbar;
	UIBarButtonItem *screenshotButton;

	NSInteger _screenshotType;
@protected
	UIView *rcView;
}

- (UIButton*)customButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;
- (void)loadImage:(id)dummy;
- (void)flipView:(id)sender;

@end
