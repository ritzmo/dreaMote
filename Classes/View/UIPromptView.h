//
//  UIPromptView.h
//  dreaMote
//
//  Created by Moritz Venn on 05.08.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	UIPromptViewStyleDefault = UIAlertViewStyleDefault,
	UIPromptViewStyleSecureTextInput = UIAlertViewStyleSecureTextInput,
	UIPromptViewStylePlainTextInput = UIAlertViewStylePlainTextInput,
	UIPromptViewStyleLoginAndPasswordInput = UIAlertViewStyleLoginAndPasswordInput
} UIPromptViewStyle;

/*!
 @brief UIPromptView is a customized UIAlertView which adds text input abilities.
 The API is close to that of the UIAlertView in iOS 5, so eventually switching over to
 the native implementation is easier.
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

@property (nonatomic, assign) UIPromptViewStyle promptViewStyle;

@end
