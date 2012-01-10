//
//  SimulatedTimerTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright (c) 2012 Moritz Venn. All rights reserved.
//

#import "SimulatedTimerTableViewCell.h"

#import <Constants.h>
#import <Configuration/DreamoteConfiguration.h>

#import <Objects/Generic/SimulatedTimer.h>

/*!
 @brief Cell identifier for this cell.
 */
NSString *kSimulatedTimerCell_ID = @"SimulatedTimerCell_ID";

@implementation SimulatedTimerTableViewCell

- (NSString *)accessibilityValue
{
	NSString *value = [super accessibilityValue];

	NSString *autotimerName = [self.timer isKindOfClass:[SimulatedTimer class]] ? ((SimulatedTimer *)self.timer).autotimerName : nil;
	if(value && autotimerName)
		value = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@, Auto-Timer %@", @"AutoTimer", @"Acessibility value for simulated autotimers. Previous acessibility value (time string) followed by autotimer name"), value, autotimerName];
	else if(autotimerName)
		value = autotimerName;
	return value;
}

- (void)drawContentRect:(CGRect)contentRect
{
	[super drawContentRect:contentRect];
	CGFloat offsetX = contentRect.origin.x;
	const CGFloat boundsWidth = contentRect.size.width;

	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	UIFont *tertiaryFont = [UIFont systemFontOfSize:singleton.timerTimeTextSize];

	CGPoint point = CGPointMake(offsetX + kLeftMargin, contentRect.size.height-tertiaryFont.lineHeight);
	CGFloat forWidth = boundsWidth - point.x;

	NSString *autotimerName = [self.timer isKindOfClass:[SimulatedTimer class]] ? ((SimulatedTimer *)self.timer).autotimerName : nil;
	[autotimerName drawAtPoint:point forWidth:forWidth withFont:tertiaryFont lineBreakMode:UILineBreakModeTailTruncation];
}

/* Workaround for accessory */
- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
	[super setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)setEditingAccessoryType:(UITableViewCellAccessoryType)editingAccessoryType
{
	[super setEditingAccessoryType:UITableViewCellAccessoryNone];
}

@end
