//
//  UIPromptView.h
//  dreaMote
//
//  Created by Moritz Venn on 05.08.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	UIPromptViewStyleDefault = 0,
#define UIAlertViewStyleDefault UIPromptViewStyleDefault
	UIPromptViewStyleSecureTextInput,
#define UIAlertViewStyleSecureTextInput UIPromptViewStyleSecureTextInput
	UIPromptViewStylePlainTextInput,
#define UIAlertViewStylePlainTextInput UIPromptViewStylePlainTextInput
	UIPromptViewStyleLoginAndPasswordInput
#define UIAlertViewStyleLoginAndPasswordInput UIPromptViewStyleLoginAndPasswordInput
} UIPromptViewStyle;
#define UIAlertViewStyle UIPromptViewStyle

/*!
 @brief UIPromptView is a customized UIAlertView which adds text input abilities.
 The API is close to that of the UIAlertView in iOS 5, so eventually switching over to
 the native implementation is easier.
 @note To hide this from Apple and (since some of these symbols were available before iOS 5)
 not appear to use private APIs we use custom names and allow to map the calls using defines.
 @note Probably does not behave exactly as the one in iOS 5, but close enough for our current
 needs.
 */
@interface UIPromptView : UIAlertView
{
@private
	UIPromptViewStyle promptViewStyle;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle;

- (UITextField *)promptFieldAtIndex:(NSInteger)promptFieldIndex;
#define textFieldAtIndex promptFieldAtIndex

@property (nonatomic, assign) UIPromptViewStyle promptViewStyle;
#define alertViewStyle promptViewStyle

@end
