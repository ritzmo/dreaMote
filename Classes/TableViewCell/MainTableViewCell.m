//
//  MainTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MainTableViewCell.h"
#import "Constants.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMainCell_ID = @"MainCell_ID";

@implementation MainTableViewCell

@synthesize dataDictionary = _dataDictionary;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]))
	{
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];

		self.detailTextLabel.backgroundColor = [UIColor clearColor];
		self.detailTextLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;
		self.detailTextLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedDetailsTextColor;
		self.detailTextLabel.font = [UIFont systemFontOfSize:kMainDetailsSize];
		self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	}
	
	return self;
}

- (void)theme
{
	self.detailTextLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;
	self.detailTextLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedDetailsTextColor;
	[super theme];
}

/* assign item */
- (void)setDataDictionary:(NSDictionary *)newDictionary
{
	// Abort if same item assigned
	if(_dataDictionary == newDictionary) return;
	_dataDictionary = newDictionary;

	// update value in subviews
	self.textLabel.text = [_dataDictionary objectForKey:@"title"];
	self.detailTextLabel.text = [_dataDictionary objectForKey:@"explainText"];

	// Redraw
	[self setNeedsDisplay];
}

@end
