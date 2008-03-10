//
//  MyCustomCell.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MyCustomCell.h"

@implementation MyCustomCell

@synthesize dataDictionary;
@synthesize nameLabel;
@synthesize explainLabel;

#define LEFT_COLUMN_OFFSET		10
#define LEFT_COLUMN_WIDTH		220
		
#define UPPER_ROW_TOP			0

#define CELL_HEIGHT				50
	

- (id)initWithFrame:(CGRect)aRect
{
	if (self = [super initWithFrame:aRect])
	{
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// Create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.opaque = NO;
		nameLabel.textColor = [UIColor blackColor];
		nameLabel.highlightColor = [UIColor whiteColor];
		nameLabel.font = [UIFont boldSystemFontOfSize:18];
		[self addSubview:nameLabel];
		
		explainLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		explainLabel.backgroundColor = [UIColor clearColor];
		explainLabel.opaque = NO;
		explainLabel.textColor = [UIColor grayColor];
		explainLabel.highlightColor = [UIColor whiteColor];
		explainLabel.font = [UIFont systemFontOfSize:14];
		[self addSubview:explainLabel];
	}
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    CGRect contentRect = [self contentRectForBounds:self.bounds];
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
    CGRect frame = CGRectMake(contentRect.origin.x + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP, LEFT_COLUMN_WIDTH, CELL_HEIGHT);
	nameLabel.frame = frame;
	
	frame = CGRectMake(contentRect.origin.x + 75 + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP, LEFT_COLUMN_WIDTH, CELL_HEIGHT);
	explainLabel.frame = frame;
}

- (void)dealloc
{
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