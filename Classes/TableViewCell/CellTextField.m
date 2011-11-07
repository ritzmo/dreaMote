/*

File: CellTextField.m
Abstract: A simple UITableViewCell that wraps a UITextField object so that you
can edit the text.

Version: 1.7

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

 
#import "CellTextField.h"
#import "Constants.h"

// cell identifier for this custom cell
NSString *kCellTextField_ID = @"CellTextField_ID";

@implementation CellTextField

@synthesize fixedWidth;
@synthesize view;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		// turn off selection use
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.textLabel.adjustsFontSizeToFitWidth = YES;
		fixedWidth = -1;
	}
	return self;
}

- (void)prepareForReuse
{
	if([view superview] == self.contentView)
	{
		[view endEditing:YES];
		[view resignFirstResponder];
		[view removeFromSuperview];
	}
	self.view = nil;
	self.textLabel.text = nil;
	fixedWidth = -1;

	[super prepareForReuse];
}

- (void)setView:(UITextField *)inView
{
	if(view == inView) return;
	if(view.delegate == self) view.delegate = nil;
	view = inView;
	view.delegate = self;

	/*!
	 @note addSubview: takes care of removing the superview
	 if it is not the current view.
	 */
	[self.contentView addSubview:inView];
	[self layoutSubviews];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	const CGRect contentRect = [self.contentView bounds];
	const UILabel *label = self.textLabel;
	const BOOL showLabel = (label.text.length > 0);

	CGRect frame;

	if(showLabel)
	{
		label.hidden = NO;
		frame = CGRectMake(contentRect.origin.x + kCellLeftOffset,
						   contentRect.origin.y + kCellTopOffset,
						   [label sizeThatFits:label.bounds.size].width,
						   kTextFieldHeight);
		CGFloat maxWidth = contentRect.size.width - (frame.origin.x + frame.size.width) - kCellLeftOffset;
		if(fixedWidth != -1)
		{
			if(maxWidth < fixedWidth)
				frame.size.width -= (fixedWidth - maxWidth);
			maxWidth = fixedWidth;
		}
		label.frame = frame;

		frame.size.width = maxWidth;
		frame.origin.x = contentRect.size.width - maxWidth - kCellLeftOffset;
	}
	else
	{
		const CGFloat maxWidth = contentRect.size.width - (kCellLeftOffset*2);
		const CGFloat width = (fixedWidth > -1 && fixedWidth < maxWidth) ? fixedWidth : maxWidth;
		label.hidden = YES;
		frame = CGRectMake(contentRect.origin.x + kCellLeftOffset,
						   contentRect.origin.y + kCellTopOffset,
						   width,
						   kTextFieldHeight);
	}

	self.view.frame  = frame;
}

- (void)dealloc
{
    if(view.delegate == self) view.delegate = nil;
    [view resignFirstResponder];
}

- (void)stopEditing
{
    [view resignFirstResponder];
    [self textFieldDidEndEditing:view];
}

#pragma mark -
#pragma mark <UITextFieldDelegate> Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL beginEditing = YES;
    // Allow the cell delegate to override the decision to begin editing.
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellShouldBeginEditing:)])
	{
        beginEditing = [self.delegate cellShouldBeginEditing:self];
    }
    // Update internal state.
    if (beginEditing)
		self.isInlineEditing = YES;
    return beginEditing;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Notify the cell delegate that editing ended.
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellShouldBeginEditing:)])
	{
        [self.delegate cellDidEndEditing:self];
    }
    // Update internal state.
    self.isInlineEditing = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self stopEditing];
    return YES;
}

@end
