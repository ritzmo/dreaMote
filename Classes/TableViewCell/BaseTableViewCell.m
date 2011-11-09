//
//  BaseTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "BaseTableViewCell.h"

#import "DreamoteConfiguration.h"

NSString *kBaseCell_ID = @"BaseCell_ID";

@implementation BaseTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		// ???
	}
	return self;
}

- (void)prepareForReuse
{
	[self theme];
	[super prepareForReuse];
}

- (void)theme
{
	/*
	DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
	switch(singleton.currentTheme)
	{
		default:
		case THEME_DEFAULT:
			break;
		case THEME_BLUE:
			break;
		case THEME_HIGHCONTRAST:
			break;
	}
	*/
}

@end
