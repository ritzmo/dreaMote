/*

File: DisplayCell.m
Abstract: UITableView utility cell that holds a UIView.

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

#import "DisplayCell.h"
#import "Constants.h"

#define kCellHeight	25

// cell identifier for this custom cell
NSString *kDisplayCell_ID = @"DisplayCell_ID";

@implementation DisplayCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		// turn off selection use
		self.selectionStyle = UITableViewCellSelectionStyleNone;

		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.opaque = NO;
		self.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
		self.textLabel.adjustsFontSizeToFitWidth = YES;
	}
	return self;
}

- (void)prepareForReuse
{
	if([view superview] == self.contentView)
		[view removeFromSuperview];
	self.view = nil;

	[super prepareForReuse];
}

- (UILabel *)nameLabel
{
	return self.textLabel;
}

- (UIView *)view
{
	return view;
}

- (void)setView:(UIView *)inView
{
	if(view == inView) return;
	if(view.superview == self.contentView)
		[view removeFromSuperview];
	view = inView;

	/*!
	 @note addSubview: takes care of removing the superview
	 if it is not the current view.
	 */
	[self.contentView addSubview:inView];
	[self setNeedsLayout];
}

- (void)layoutSubviews
{	
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];

	if ([view isKindOfClass:[UIPageControl class]])
	{
		// special case UIPageControl since its width changes after its creation
		CGRect frame = self.view.frame;
		frame.size.width = kPageControlWidth;
		self.view.frame = frame;
	}

	CGRect uiFrame = CGRectMake(contentRect.size.width - self.view.bounds.size.width - kCellLeftOffset,
								(CGFloat)round((contentRect.size.height - self.view.bounds.size.height) / 2.0),
								self.view.bounds.size.width,
								self.view.bounds.size.height);
	view.frame = uiFrame;

	CGRect frame = CGRectMake(contentRect.origin.x + kCellLeftOffset, kCellTopOffset, uiFrame.origin.x - (2 * kCellLeftOffset), kCellHeight);
	self.textLabel.frame = frame;
}


@end
