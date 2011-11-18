//
//  RCEmulatorController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZoomingScrollView.h"

/*!
 @brief Basic Emulated Remote Control.
 
 Generic remote control screen which only needs the rcView to be set up by extending
 classes. Screenshot functionality is already included.
 */
@interface RCEmulatorController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>
{
@private
	BOOL _shouldVibrate; /*!< @brief Vibrate as response to successfully sent RC code? */

	UIView *_screenView; /*!< @brief Screenshot View. */
	ZoomingScrollView *_scrollView; /*!< @brief Container of Screenshot View. */
	UIImageView *_imageView; /*!< @brief Actual Screenshot UI Item. */
	UIBarButtonItem *_screenshotButton; /*!< @brief Button to quickly change to Screenshot View. */
	NSOperationQueue *_queue; /*!< @brief NSOperationQueue for button presses. */

	NSInteger _screenshotType; /*!< @brief Selected Screenshot type. */
@protected
	IBOutlet UIToolbar *toolbar; /*!< @brief Toolbar. */
	IBOutlet UIView *contentView; /*!< @brief Container view. */
	IBOutlet UIView *rcView; /*!< @brief Remote Controller view. */
	UIView *_keyPad; /*!< @brief View containing Number keys. */
	UIView *_navigationPad; /*!< @brief View containing Navigation keys. */

	CGRect _landscapeFrame; /*!< @brief Frame for rcView in landscape orientation. */
	CGRect _portraitFrame; /*!< @brief Frame for rcView in portrait orientation. */
	CGRect _landscapeNavigationFrame; /*!< @brief Frame for _navigationPad in landscape orientation. */
	CGRect _portraitNavigationFrame; /*!< @brief Frame for _navigationPad in portrait orientation. */
	CGRect _portraitKeyFrame; /*!< @brief Frame of _keyPad in portrait orientation. */
}

/*!
 @brief Actual RC Emulator.
 */
@property (nonatomic,strong) IBOutlet UIView *rcView;

/*!
 @brief Toolbar.
 */
@property (nonatomic,readonly) UIToolbar *toolbar;

/*!
 @brief Create custom Button.
 
 @param frame Button Frame.
 @param imagePath Path to Button Image.
 @param keyCode RC Code.
 @return UIButton instance.
 */
- (UIButton*)newButton:(CGRect)frame withImage:(NSString*)imagePath andKeyCode:(int)keyCode;

/*!
 @brief Load Image.
 
 @param dummy Unused parameter required by Buttons.
 */
- (void)loadImage:(id)dummy;

/*!
 @brief Flip Views.
 
 @param sender Unused parameter required by Buttons.
 */
- (IBAction)flipView:(id)sender;

/*!
 * @brief Send RC code.
 *
 * @param rcCode Code to send.
 */
- (void)sendButton: (NSNumber *)rcCode;

/*!
 * @brief Button from xib pressed.
 *
 * @param sender Button instance triggering this action.
 */
- (IBAction)buttonPressedIB: (id)sender;

@end
