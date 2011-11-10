//
//  BaseTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "BaseTableViewCell.h"

#import <Configuration/DreamoteConfiguration.h>
#import <View/ColoredAccessoryView.h>

NSString *kBaseCell_ID = @"BaseCell_ID";

@implementation BaseTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
		self.textLabel.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)prepareForReuse
{
	self.accessoryType = self.accessoryType;
	self.editingAccessoryType = self.editingAccessoryType;
	[self theme];
	[super prepareForReuse];
}

- (void)theme
{
	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	self.textLabel.textColor = singleton.textColor;
	self.textLabel.highlightedTextColor = singleton.highlightedTextColor;
	/*
	switch(singleton.currentTheme)
	{
		default:
		case THEME_DEFAULT:
			break;
		case THEME_BLUE:
			break;
		case THEME_NIGHT:
			break;
	}
	*/
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
	[super setAccessoryType:accessoryType];
	if(accessoryType == UITableViewCellAccessoryDisclosureIndicator && [DreamoteConfiguration singleton].currentTheme == THEME_NIGHT)
	{
		ColoredAccessoryView *cav = [ColoredAccessoryView accessoryViewWithColor:[DreamoteConfiguration singleton].detailsTextColor
															 andHighlightedColor:[DreamoteConfiguration singleton].highlightedDetailsTextColor];
		self.accessoryView = cav;
	}
	else
		self.accessoryView = nil;
}

- (void)setEditingAccessoryType:(UITableViewCellAccessoryType)editingAccessoryType
{
	[super setEditingAccessoryType:editingAccessoryType];
	if(editingAccessoryType == UITableViewCellAccessoryDisclosureIndicator && [DreamoteConfiguration singleton].currentTheme == THEME_NIGHT)
	{
		ColoredAccessoryView *cav = [ColoredAccessoryView accessoryViewWithColor:[DreamoteConfiguration singleton].detailsTextColor
															 andHighlightedColor:[DreamoteConfiguration singleton].highlightedDetailsTextColor];
		self.editingAccessoryView = cav;
	}
	else
		self.editingAccessoryView = nil;
}

@end
