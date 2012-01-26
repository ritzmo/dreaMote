//
//  ConnectionTableViewCell.m
//  dreaMote
//
//  Created by Moritz Venn on 23.06.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "ConnectionTableViewCell.h"
#import "Constants.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kConnectionCell_ID = @"ConnectionCell_ID";

@implementation ConnectionTableViewCell

@synthesize dataDictionary = _dataDictionary;

/* initialize */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		// you can do this here specifically or at the table level for all cells
		self.accessoryType = UITableViewCellAccessoryNone;

		// Create label views to contain the various pieces of text that make up the cell.
		// Add these as subviews.
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.textLabel.opaque = NO;
		self.textLabel.textColor = [DreamoteConfiguration singleton].textColor;
		self.textLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
		self.textLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];

		_descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_descriptionLabel.backgroundColor = [UIColor clearColor];
		_descriptionLabel.opaque = NO;
		_descriptionLabel.textColor = [DreamoteConfiguration singleton].textColor;
		_descriptionLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
		_descriptionLabel.font = [UIFont boldSystemFontOfSize:kMainDetailsSize];
		_descriptionLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:_descriptionLabel];

		_statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_statusLabel.backgroundColor = [UIColor clearColor];
		_statusLabel.opaque = NO;
		_statusLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;
		_statusLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedDetailsTextColor;
		_statusLabel.font = [UIFont systemFontOfSize:kMainDetailsSize];
		_statusLabel.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:_statusLabel];
	}
	
	return self;
}

- (void)theme
{
	_descriptionLabel.textColor = [DreamoteConfiguration singleton].textColor;
	_descriptionLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
	_statusLabel.textColor = [DreamoteConfiguration singleton].detailsTextColor;
	_statusLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedDetailsTextColor;
	[super theme];
}

/* layout */
- (void)layoutSubviews
{
	CGRect frame;

	[super layoutSubviews];
	const CGRect contentRect = [self.contentView bounds];
	CGFloat offset = (IS_IPAD()) ? 3 : 0;

	CGSize labelSize = [_statusLabel sizeThatFits:_statusLabel.bounds.size];

	frame = CGRectMake(contentRect.origin.x + kLeftMargin, offset, contentRect.size.width - labelSize.width - kLeftMargin, 26);
	self.textLabel.frame = frame;

	offset = (IS_IPAD()) ? 28 : 21;
	frame.origin.y = offset;
	frame.size.height = 22;
	frame = CGRectMake(contentRect.origin.x + kLeftMargin, offset, contentRect.size.width - labelSize.width - kLeftMargin, 22);
	_descriptionLabel.frame = frame;

	frame.origin.x = frame.origin.x + frame.size.width - kRightMargin;
	frame.origin.y = (contentRect.size.height - kMainDetailsSize) / 2.0f;
	frame.size.width = labelSize.width;
	_statusLabel.frame = frame;
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	
	// when the selected state changes, set the highlighted state of the lables accordingly
	_statusLabel.highlighted = selected;
	_descriptionLabel.highlighted = selected;
}

/* assign item */
- (void)setDataDictionary:(NSDictionary *)newDictionary
{
	// Abort if same item assigned
	if(_dataDictionary == newDictionary) return;
	_dataDictionary = newDictionary;
	
	// update value in subviews
	self.textLabel.text = [newDictionary objectForKey:kRemoteHost];
	_statusLabel.text = [[newDictionary objectForKey:kLoginFailed] boolValue] ? NSLocalizedString(@"unreachable", @"Label text in AutoConfiguration if host is unreachable") : nil;

	NSString *username = [newDictionary objectForKey:kUsername];
	NSString *password = [newDictionary objectForKey:kPassword];
	NSString *authenticationString = nil;
	if(!username || !password || ![username length])
	{
		authenticationString = NSLocalizedString(@"no authentication", @"");
	}
	else if(![password length])
	{
		authenticationString = username;
	}
	else
	{
		authenticationString = [NSString stringWithFormat:@"%@:%@", username, password];
	}
	_descriptionLabel.text = [NSString stringWithFormat:@"%@ (%@)", authenticationString, [[newDictionary objectForKey:kSSL] boolValue] ? NSLocalizedString(@"encrypted", @"") : NSLocalizedString(@"not encrypted", @"")];

	// Redraw
	[self setNeedsDisplay];
}

@end
