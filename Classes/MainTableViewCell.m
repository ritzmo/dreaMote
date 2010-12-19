//
//  MainTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "MainTableViewCell.h"
#import "Constants.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMainCell_ID = @"MainCell_ID";

@implementation MainTableViewCell

@synthesize dataDictionary = _dataDictionary;
@synthesize nameLabel = _nameLabel;
@synthesize explainLabel = _explainLabel;

/* initialize */
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
#ifdef __IPHONE_3_0
	if((self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier]))
#else
	if((self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier]))
#endif
	{
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// Create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		_nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		_nameLabel.backgroundColor = [UIColor clearColor];
		_nameLabel.opaque = NO;
		_nameLabel.textColor = [UIColor blackColor];
		_nameLabel.highlightedTextColor = [UIColor whiteColor];
		_nameLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];
		[self.contentView addSubview:_nameLabel];

		// Explanation label
		_explainLabel = [[UILabel alloc] initWithFrame:CGRectZero];	// layoutSubViews will decide the final frame
		_explainLabel.backgroundColor = [UIColor clearColor];
		_explainLabel.opaque = NO;
		_explainLabel.textColor = [UIColor grayColor];
		_explainLabel.highlightedTextColor = [UIColor whiteColor];
		_explainLabel.font = [UIFont systemFontOfSize:kMainDetailsSize];
		[self.contentView addSubview:_explainLabel];
	}
	
	return self;
}

/* layout */
- (void)layoutSubviews
{
	CGRect frame;

	[super layoutSubviews];
	const CGRect contentRect = [self.contentView bounds];

	frame = CGRectMake(contentRect.origin.x + kLeftMargin, 0, contentRect.size.width - kRightMargin, 26);
	_nameLabel.frame = frame;

	if(IS_IPAD())
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 25, contentRect.size.width - kRightMargin, 22);
	else
		frame = CGRectMake(contentRect.origin.x + kLeftMargin, 21, contentRect.size.width - kRightMargin, 22);
	_explainLabel.frame = frame;
}

/* dealloc */
- (void)dealloc
{
	[_nameLabel release];
	[_explainLabel release];
	[_dataDictionary release];

	[super dealloc];
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	// when the selected state changes, set the highlighted state of the lables accordingly
	_nameLabel.highlighted = selected;
}

/* assign item */
- (void)setDataDictionary:(NSDictionary *)newDictionary
{
	// Abort if same item assigned
	if (_dataDictionary == newDictionary) return;

	// Free old item, assign new
	[_dataDictionary release];
	_dataDictionary = [newDictionary retain];
	
	// update value in subviews
	_nameLabel.text = [_dataDictionary objectForKey:@"title"];
	_explainLabel.text = [_dataDictionary objectForKey:@"explainText"];

	// Redraw
	[self setNeedsDisplay];
}

@end
