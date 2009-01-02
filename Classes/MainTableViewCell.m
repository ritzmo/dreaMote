//
//  MainTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MainTableViewCell.h"
#import "Constants.h"

// cell identifier for this custom cell
NSString *kMainCell_ID = @"MainCell_ID";

@implementation MainTableViewCell

@synthesize dataDictionary;
@synthesize nameLabel;
@synthesize explainLabel;

- (id)initWithFrame:(CGRect)aRect reuseIdentifier:(NSString *)identifier
{
	self = [super initWithFrame:aRect reuseIdentifier:identifier];
	if (self)
	{
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// Create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.opaque = NO;
		nameLabel.textColor = [UIColor blackColor];
		nameLabel.highlightedTextColor = [UIColor whiteColor];
		nameLabel.font = [UIFont boldSystemFontOfSize:18];
		[self.contentView addSubview:nameLabel];
		
		explainLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		explainLabel.backgroundColor = [UIColor clearColor];
		explainLabel.opaque = NO;
		explainLabel.textColor = [UIColor grayColor];
		explainLabel.highlightedTextColor = [UIColor whiteColor];
		explainLabel.font = [UIFont systemFontOfSize:14];
		[self.contentView addSubview:explainLabel];
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];

	// In this example we will never be editing, but this illustrates the appropriate pattern
    CGRect frame = CGRectMake(contentRect.origin.x + kLeftMargin, 0, contentRect.size.width - kRightMargin, 26);
	nameLabel.frame = frame;

	frame = CGRectMake(contentRect.origin.x + kLeftMargin, 23, contentRect.size.width - kRightMargin, 20);
	explainLabel.frame = frame;
}

- (void)dealloc
{
	[nameLabel release];
	[explainLabel release];
	[dataDictionary release];

    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	// when the selected state changes, set the highlighted state of the lables accordingly
	nameLabel.highlighted = selected;
}

- (void)setDataDictionary:(NSDictionary *)newDictionary
{
	if (dataDictionary == newDictionary)
	{
		return;
	}
	[dataDictionary release];
	dataDictionary = [newDictionary retain];
	
	// update value in subviews
	nameLabel.text = [dataDictionary objectForKey:@"title"];
	explainLabel.text = [dataDictionary objectForKey:@"explainText"];
}

@end
