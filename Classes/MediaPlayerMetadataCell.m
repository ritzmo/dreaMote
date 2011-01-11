//
//  MediaPlayerMetadataCell.m
//  dreaMote
//
//  Created by Moritz Venn on 11.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MediaPlayerMetadataCell.h"
#import "Constants.h"

/*!
 @brief Cell identifier for this cell.
 */
NSString *kMetadataCell_ID = @"MetadataCell_ID";

@implementation MediaPlayerMetadataCell

/* initialize */
- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
#ifdef __IPHONE_3_0
	if((self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier]))
#else
	if((self = [super initWithFrame: frame reuseIdentifier: reuseIdentifier]))
#endif
	{
		self.accessoryType = UITableViewCellAccessoryNone;

		// Create label views to contain the various pieces of text that make up the cell.
		// Album label
		_albumLabel = [[UILabel alloc] initWithFrame:CGRectZero]; // layoutSubViews will decide the final frame
		_albumLabel.backgroundColor = [UIColor clearColor];
		_albumLabel.opaque = NO;
		_albumLabel.textColor = [UIColor blackColor];
		_albumLabel.highlightedTextColor = [UIColor whiteColor];
		_albumLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];
		_albumLabel.text = NSLocalizedString(@"Album", @"");
		[self.contentView addSubview:_albumLabel];

		// Album name label
		_album = [[UILabel alloc] initWithFrame:CGRectZero];
		_album.backgroundColor = [UIColor clearColor];
		_album.opaque = NO;
		_album.textColor = [UIColor grayColor];
		_album.highlightedTextColor = [UIColor whiteColor];
		_album.font = [UIFont systemFontOfSize:kMainDetailsSize];
		[self.contentView addSubview:_album];

		// Artist label
		_artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_artistLabel.backgroundColor = [UIColor clearColor];
		_artistLabel.opaque = NO;
		_artistLabel.textColor = [UIColor blackColor];
		_artistLabel.highlightedTextColor = [UIColor whiteColor];
		_artistLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];
		_artistLabel.text = NSLocalizedString(@"Artist", @"");
		[self.contentView addSubview:_artistLabel];

		// Artist name label
		_artist = [[UILabel alloc] initWithFrame:CGRectZero];
		_artist.backgroundColor = [UIColor clearColor];
		_artist.opaque = NO;
		_artist.textColor = [UIColor grayColor];
		_artist.highlightedTextColor = [UIColor whiteColor];
		_artist.font = [UIFont systemFontOfSize:kMainDetailsSize];
		[self.contentView addSubview:_artist];

		// Genre label
		_genreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_genreLabel.backgroundColor = [UIColor clearColor];
		_genreLabel.opaque = NO;
		_genreLabel.textColor = [UIColor blackColor];
		_genreLabel.highlightedTextColor = [UIColor whiteColor];
		_genreLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];
		_genreLabel.text = NSLocalizedString(@"Genre", @"");
		[self.contentView addSubview:_genreLabel];

		// Genre name label
		_genre = [[UILabel alloc] initWithFrame:CGRectZero];
		_genre.backgroundColor = [UIColor clearColor];
		_genre.opaque = NO;
		_genre.textColor = [UIColor grayColor];
		_genre.highlightedTextColor = [UIColor whiteColor];
		_genre.font = [UIFont systemFontOfSize:kMainDetailsSize];
		[self.contentView addSubview:_genre];

		// Title label
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.opaque = NO;
		_titleLabel.textColor = [UIColor blackColor];
		_titleLabel.highlightedTextColor = [UIColor whiteColor];
		_titleLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];
		_titleLabel.text = NSLocalizedString(@"Title", @"");
		[self.contentView addSubview:_titleLabel];

		// Actual title label
		_title = [[UILabel alloc] initWithFrame:CGRectZero];
		_title.backgroundColor = [UIColor clearColor];
		_title.opaque = NO;
		_title.textColor = [UIColor grayColor];
		_title.highlightedTextColor = [UIColor whiteColor];
		_title.font = [UIFont systemFontOfSize:kMainDetailsSize];
		[self.contentView addSubview:_title];

		// Year label
		_yearLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_yearLabel.backgroundColor = [UIColor clearColor];
		_yearLabel.opaque = NO;
		_yearLabel.textColor = [UIColor blackColor];
		_yearLabel.highlightedTextColor = [UIColor whiteColor];
		_yearLabel.font = [UIFont boldSystemFontOfSize:kMainTextSize];
		_yearLabel.text = NSLocalizedString(@"Year", @"");
		[self.contentView addSubview:_yearLabel];

		// Actual year label
		_year = [[UILabel alloc] initWithFrame:CGRectZero];
		_year.backgroundColor = [UIColor clearColor];
		_year.opaque = NO;
		_year.textColor = [UIColor grayColor];
		_year.highlightedTextColor = [UIColor whiteColor];
		_year.font = [UIFont systemFontOfSize:kMainDetailsSize];
		[self.contentView addSubview:_year];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_albumLabel release];
	[_album release];
	[_artistLabel release];
	[_artist release];
	[_genreLabel release];
	[_genre release];
	[_titleLabel release];
	[_title release];
	[_yearLabel release];
	[_year release];
	[_coverart release];
	[_metadata release];

	[super dealloc];
}

/* (de)select */
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	// so far we don't want to be selected…
	return;
}

/* get metadata */
- (NSObject<MetadataProtocol> *)metadata
{
	return _metadata;
}

/* set metadata */
- (void)setMetadata:(NSObject <MetadataProtocol>*)new
{
	if([_metadata isEqual:new]) return;

	[_metadata release];
	_metadata = [new retain];

	// update text in subviews
	_album.text = _metadata.album;
	_artist.text = _metadata.artist;
	_genre.text = _metadata.genre;
	_title.text = _metadata.title;
	_year.text = _metadata.year;

	// Redraw
	[self setNeedsDisplay];
}

/* get coverart */
- (UIImageView *)coverart
{
	return _coverart;
}

/* set coverart */
- (void)setCoverart:(UIImageView *)new
{
	if([_coverart isEqual:new]) return;
	if(_coverart)
		[_coverart removeFromSuperview];

	[_coverart release];
	_coverart = [new retain];

	if(new)
		[self.contentView addSubview:new];

	// Redraw
	[self setNeedsDisplay];
}

/* layout */
- (void)layoutSubviews
{
	CGRect frame;

	[super layoutSubviews];
	const CGRect contentRect = [self.contentView bounds];
	// don't subtract any size for missing cover and differnt sizes by orientation
	const CGFloat metadataDimension = (_coverart == nil) ? 0 :
		(UIInterfaceOrientationIsPortrait([UIDevice currentDevice].orientation)) ?
			kMetadataDimensionPortrait : kMetadataDimensionLandscape;
	frame = CGRectMake(contentRect.origin.x + kLeftMargin, 0, contentRect.size.width - kLeftMargin - kRightMargin - metadataDimension, 0);

	// title, artist, album, year, genre
	frame.origin.y = 8;
	frame.size.height = 26;
	_titleLabel.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 22;
	_title.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 26;
	_artistLabel.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 22;
	_artist.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 26;
	_albumLabel.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 22;
	_album.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 26;
	_yearLabel.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 22;
	_year.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 26;
	_genreLabel.frame = frame;

	frame.origin.y += 26;
	frame.size.height = 22;
	_genre.frame = frame;

	// Coverart
	frame = CGRectMake(contentRect.size.width - kRightMargin - metadataDimension, (contentRect.size.height - metadataDimension) / 2.0f, metadataDimension, metadataDimension);
	_coverart.frame = frame;
}

@end
