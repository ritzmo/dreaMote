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

/* dealloc */
- (void)dealloc
{
	[begin release];
	[firstTime release];
	[secondTime release];
	[thirdTime release];

	[super dealloc];
}

/* initialize */
- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		firstTime = [self newLabelWithPrimaryColor:[UIColor blackColor]
									 selectedColor:[UIColor whiteColor]
										  fontSize:kMultiEPGFontSize
											  bold:YES];

		secondTime = [self newLabelWithPrimaryColor:[UIColor blackColor]
									 selectedColor:[UIColor whiteColor]
										  fontSize:kMultiEPGFontSize
											  bold:YES];

		thirdTime = [self newLabelWithPrimaryColor:[UIColor blackColor]
									 selectedColor:[UIColor whiteColor]
										  fontSize:kMultiEPGFontSize
											  bold:YES];		

		fourthTime = [self newLabelWithPrimaryColor:[UIColor blackColor]
									 selectedColor:[UIColor whiteColor]
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

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];

	const CGFloat interval = [[[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval] floatValue];
	const CGFloat widthPerSecond = (frame.size.width - kServiceWidth) / interval;
	const CGFloat leftOffset = kServiceWidth / 2;
	firstTime.frame = CGRectMake(frame.origin.x + leftOffset, frame.origin.y, kServiceWidth, frame.size.height);
	secondTime.frame = CGRectMake(firstTime.frame.origin.x + (interval / 4) * widthPerSecond, frame.origin.y, kServiceWidth, frame.size.height);
	thirdTime.frame = CGRectMake(secondTime.frame.origin.x + (interval / 4) * widthPerSecond, frame.origin.y, kServiceWidth, frame.size.height);
	fourthTime.frame = CGRectMake(thirdTime.frame.origin.x + (interval / 4) * widthPerSecond, frame.origin.y, kServiceWidth, frame.size.height);
}

- (NSDate *)begin
{
	return begin;
}

- (void)setBegin:(NSDate *)newBegin
{
	if(begin == newBegin) return;

	[begin release];
	begin = [newBegin retain];

	const NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	const NSNumber *interval = [stdDefaults objectForKey:kMultiEPGInterval];
	const NSTimeInterval quarter = [interval floatValue] / 4;

	const NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	firstTime.text = [formatter fuzzyDate:begin];

	[formatter setDateStyle:NSDateFormatterNoStyle];
	NSDate *current = [begin dateByAddingTimeInterval:quarter];
	secondTime.text = [formatter stringFromDate:current];

	current = [current dateByAddingTimeInterval:quarter];
	thirdTime.text = [formatter stringFromDate:current];

	current = [current dateByAddingTimeInterval:quarter];
	fourthTime.text = [formatter stringFromDate:current];
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
