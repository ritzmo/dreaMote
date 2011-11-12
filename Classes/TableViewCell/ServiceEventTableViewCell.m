//
//  ServiceEventTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"
#import "ServiceEventTableViewCell.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kServiceEventCell_ID = @"ServiceEventCell_ID";

@implementation ServiceEventTableViewCell

@synthesize cellView;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		const UIView *myContentView = self.contentView;
		self.accessoryType = UITableViewCellAccessoryNone;
		self.backgroundColor = [UIColor clearColor];

		cellView = [[ServiceEventCellContentView alloc] initWithFrame:myContentView.bounds];
		cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[myContentView addSubview:cellView];
	}

	return self;
}

- (void)prepareForReuse
{
	self.accessoryType = UITableViewCellAccessoryNone;
	cellView.now = nil;
	cellView.next = nil;
	// NOTE: the content view will redraw itself as we always set now AND next

	[super prepareForReuse];
}

@end
