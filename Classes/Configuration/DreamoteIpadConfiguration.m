//
//  DreamoteIpadConfiguration.m
//  dreaMote
//
//  Created by Moritz Venn on 08.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "DreamoteIpadConfiguration.h"

@implementation DreamoteIpadConfiguration

- (UIColor *)groupedTableViewBackgroundColor
{
	if(self.currentTheme == THEME_DEFAULT)
		return [UIColor colorWithRed:0.821f green:0.834f blue:0.860f alpha:1];
	return self.backgroundColor;
}

- (CGFloat)textFieldHeight
{
	return 35;
}

- (CGFloat)textViewHeight
{
	return 300;
}

- (CGFloat)textFieldFontSize
{
	return 22;
}

- (CGFloat)textViewFontSize
{
	return 22;
}

- (CGFloat)multiEpgFontSize
{
	return 16;
}

- (CGFloat)uiSmallRowHeight
{
	return 43;
}

- (CGFloat)uiRowHeight
{
	return 55;
}

- (CGFloat)uiRowLabelHeight
{
	return 22;
}

- (CGFloat)eventCellHeight
{
	return 53;
}

- (CGFloat)serviceCellHeight
{
	return 38;
}

- (CGFloat)serviceEventCellHeight
{
	return 60;
}

- (CGFloat)metadataCellHeight
{
	return 275;
}

- (CGFloat)autotimerCellHeight
{
	return 38;
}

- (CGFloat)packageCellHeight
{
	return 50;
}

- (CGFloat)multiEpgHeaderHeight
{
	return 40;
}

- (CGFloat)mainTextSize
{
	return 22;
}

- (CGFloat)mainDetailsSize
{
	return 18;
}

- (CGFloat)serviceTextSize
{
	return 20;
}

- (CGFloat)serviceEventServiceSize
{
	return 18;
}

- (CGFloat)serviceEventEventSize
{
	return 15;
}

- (CGFloat)eventNameTextSize
{
	return 18;
}

- (CGFloat)eventDetailsTextSize
{
	return 15;
}

- (CGFloat)timerServiceTextSize
{
	return 20;
}

- (CGFloat)timerNameTextSize
{
	return 15;
}

- (CGFloat)timerTimeTextSize
{
	return 15;
}

- (CGFloat)datePickerFontSize
{
	return 26;
}

- (CGFloat)autotimerNameTextSize
{
	return 20;
}

- (CGFloat)packageNameTextSize
{
	return 21;
}

- (CGFloat)packageVersionTextSize
{
	return 18;
}

@end
