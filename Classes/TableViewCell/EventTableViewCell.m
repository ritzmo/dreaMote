//
//  EventTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventTableViewCell.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kEventCell_ID = @"EventCell_ID";

@implementation EventTableViewCell

@synthesize cellView;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		const UIView *myContentView = self.contentView;
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.backgroundColor = [UIColor clearColor];

		cellView = [[EventCellContentView alloc] initWithFrame:myContentView.bounds];
		cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[myContentView addSubview:cellView];
	}

	return self;
}

@end
