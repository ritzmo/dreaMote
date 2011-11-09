//
//  MultiEPGHeaderView.m
//  dreaMote
//
//  Created by Moritz Venn on 10.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "MultiEPGHeaderView.h"

#import "NSDateFormatter+FuzzyFormatting.h"

#define kServiceWidth ((IS_IPAD()) ? 100 : 75)

/*!
 @brief Private functions of MultiEPGHeaderView.
 */
@interface MultiEPGHeaderView()
/*!
 @brief Private helper to create a label.
 */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold;
@end

@implementation MultiEPGHeaderView

/* initialize */
- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		self.opaque = NO;

		firstTime = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].textColor
									 selectedColor:nil
										  fontSize:kMultiEPGFontSize
											  bold:YES];

		secondTime = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].textColor
									 selectedColor:nil
										  fontSize:kMultiEPGFontSize
											  bold:YES];

		thirdTime = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].textColor
									 selectedColor:nil
										  fontSize:kMultiEPGFontSize
											  bold:YES];		

		fourthTime = [self newLabelWithPrimaryColor:[DreamoteConfiguration singleton].textColor
									 selectedColor:nil
										  fontSize:kMultiEPGFontSize
											  bold:YES];

		const CGFloat interval = [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
		const CGFloat widthPerSecond = (frame.size.width - kServiceWidth) / interval;
		const CGFloat leftOffset = kServiceWidth / 2;
		firstTime.frame = CGRectMake(frame.origin.x + leftOffset, frame.origin.y, kServiceWidth, frame.size.height);
		secondTime.frame = CGRectMake(firstTime.frame.origin.x + (interval / 2.8f) * widthPerSecond, frame.origin.y, kServiceWidth, frame.size.height);
		thirdTime.frame = CGRectMake(secondTime.frame.origin.x + (interval / 2.8f) * widthPerSecond, frame.origin.y, kServiceWidth, frame.size.height);
		fourthTime.frame = CGRectMake(thirdTime.frame.origin.x + (interval / 2.8f) * widthPerSecond, frame.origin.y, kServiceWidth, frame.size.height);

		[self addSubview:firstTime];
		[self addSubview:secondTime];
		[self addSubview:thirdTime];
		[self addSubview:fourthTime];
	}

	return self;
}

- (void)theme
{
	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	firstTime.textColor = singleton.textColor;
	secondTime.textColor = singleton.textColor;
	thirdTime.textColor = singleton.textColor;
	fourthTime.textColor = singleton.textColor;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];

	const CGFloat interval = [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	const CGFloat widthPerSecond = (frame.size.width - kServiceWidth) / interval;
	const CGFloat leftOffset = kServiceWidth / 2;

	CGFloat factor = 1;
	if(interval == 1800)
		factor = 2;
	else if(interval == 5400)
		factor = 3;
	else
		factor = 4;

	CGRect myFrame = CGRectMake(frame.origin.x + leftOffset, frame.origin.y, kServiceWidth, frame.size.height);
	const CGFloat step = (interval / factor) * widthPerSecond;
	firstTime.frame = myFrame;
	myFrame.origin.x += step;
	secondTime.frame = myFrame;
	if(factor > 2)
	{
		myFrame.origin.x += step;
		thirdTime.frame = myFrame;
		if(factor > 3)
			myFrame.origin.x += step;
		else
			myFrame = CGRectZero;
		fourthTime.frame = myFrame;
	}
	else
	{
		thirdTime.frame = CGRectZero;
		fourthTime.frame = CGRectZero;
	}
}

- (NSDate *)begin
{
	return begin;
}

- (void)setBegin:(NSDate *)newBegin
{
	if(begin == newBegin) return;

	begin = newBegin;

	const NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	const NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	const CGFloat interval = [[stdDefaults objectForKey:kMultiEPGInterval] floatValue];
	NSDate *current = begin;
	NSTimeInterval step = 0;
	if(interval == 1800)
		step = interval / 2;
	else if(interval == 5400)
		step = interval / 3;
	else
		step = interval / 4;

	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	firstTime.text = [formatter fuzzyDate:begin];

	[formatter setDateStyle:NSDateFormatterNoStyle];
	current = [current dateByAddingTimeInterval:step];
	secondTime.text = [formatter stringFromDate:current];

	current = [current dateByAddingTimeInterval:step];
	thirdTime.text = [formatter stringFromDate:current];

	current = [current dateByAddingTimeInterval:step];
	fourthTime.text = [formatter stringFromDate:current];

}

/* draw cell */
- (void)drawRect:(CGRect)rect
{
	const CGRect contentRect = self.bounds;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(ctx, 0.5f, 0.5f, 0.5f, 1.0f);
	CGContextSetLineWidth(ctx, 0.25f);
	CGContextMoveToPoint(ctx, 0, contentRect.size.height);
	CGContextAddLineToPoint(ctx, contentRect.size.width, contentRect.size.height);
	CGContextStrokePath(ctx);
}

/* Create and configure a label. */
- (UILabel *)newLabelWithPrimaryColor:(UIColor *) primaryColor selectedColor:(UIColor *) selectedColor fontSize:(CGFloat) fontSize bold:(BOOL) bold
{
	UIFont *font;
	UILabel *newLabel;

	if (bold) {
		font = [UIFont boldSystemFontOfSize:fontSize];
	} else {
		font = [UIFont systemFontOfSize:fontSize];
	}

	newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor clearColor];
	newLabel.opaque = NO;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	newLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	newLabel.numberOfLines = 0;
	newLabel.adjustsFontSizeToFitWidth = YES;
	newLabel.textAlignment = UITextAlignmentCenter;
	
	return newLabel;
}

@end
