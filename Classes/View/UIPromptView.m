//
//  UIPromptView.m
//  dreaMote
//
//  Created by Moritz Venn on 05.08.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "UIPromptView.h"

#import "UIDevice+SystemVersion.h"

enum textfieldTags
{
	TEXT_FIELD_0 = 99,
	TEXT_FIELD_1 = 100,
};

@implementation UIPromptView

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle
{
    if((self = [super initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:okButtonTitle, nil]))
	{
        // Initialization code here.
    }

    return self;
}

- (UIPromptViewStyle)promptViewStyle
{
	return promptViewStyle;
}

- (void)setPromptViewStyle:(UIPromptViewStyle)newPromptViewStyle
{
	if(promptViewStyle == newPromptViewStyle) return;

	promptViewStyle = newPromptViewStyle;

	if(newPromptViewStyle == UIPromptViewStyleDefault) return;

	UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 31.0)];
	theTextField.tag = TEXT_FIELD_0;
	[theTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	[theTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
	[theTextField setBorderStyle:UITextBorderStyleRoundedRect];
	[theTextField setBackgroundColor:[UIColor clearColor]];
	[theTextField setTextAlignment:UITextAlignmentCenter];
	[self addSubview:theTextField];
	[theTextField release];

	CGFloat offset;
	if(newPromptViewStyle == UIPromptViewStyleLoginAndPasswordInput)
	{
		theTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 85.0, 260.0, 25.0)];
		theTextField.tag = TEXT_FIELD_1;
		[theTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
		[theTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
		[theTextField setBorderStyle:UITextBorderStyleRoundedRect];
		[theTextField setBackgroundColor:[UIColor clearColor]];
		[theTextField setTextAlignment:UITextAlignmentCenter];
		[theTextField setSecureTextEntry:YES];
		[self addSubview:theTextField];
		[theTextField release];

		self.message = @"\n\n\n";
		offset = 110.0;
	}
	else
	{
		self.message = @"\n";
		offset = 130.0;
	}
	
	if(![UIDevice runsIos4OrBetter])
	{
		CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, offset); 
		[self setTransform:translate];
	}
}

- (void)show
{
	if(promptViewStyle != UIPromptViewStyleDefault)
	{
		UITextField *field = (UITextField *)[self viewWithTag:TEXT_FIELD_0];
		[field becomeFirstResponder];
	}
	[super show];
}

- (UITextField *)promptFieldAtIndex:(NSInteger)promptFieldIndex
{
	if(promptFieldIndex == 0 && promptViewStyle != UIPromptViewStyleDefault)
	{
		UITextField *field = (UITextField *)[self viewWithTag:TEXT_FIELD_0];
		return SafeReturn(field);
	}
	else if(promptFieldIndex == 1 && promptViewStyle == UIPromptViewStyleLoginAndPasswordInput)
	{
		UITextField *field = (UITextField *)[self viewWithTag:TEXT_FIELD_1];
		return SafeReturn(field);
	}

	NSException *e = [NSException exceptionWithName:NSRangeException reason:@"promptFieldIndex out of range" userInfo:nil];
	[e raise];
	return nil;
}

@end
