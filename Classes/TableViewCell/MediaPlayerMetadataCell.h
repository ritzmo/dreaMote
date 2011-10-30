//
//  MediaPlayerMetadataCell.h
//  dreaMote
//
//  Created by Moritz Venn on 11.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MetadataProtocol.h"

/*!
 @brief Cell identifier for this cell.
 */
extern NSString *kMetadataCell_ID;

/*!
 @brief UITableViewCell used to display Metainformation in MediaPlayer.
 */
@interface MediaPlayerMetadataCell : UITableViewCell
{
@private
	NSObject<MetadataProtocol> *_metadata; /*!< @brief Current set of Metadata. */
	UIImageView *_coverart; /*!< @brief Coverart associated with currently played track. */

	UILabel	*_albumLabel; /*!< @brief "Album" Label. */
	UILabel	*_album; /*!< @brief Album name Label. */
	UILabel	*_artistLabel; /*!< @brief "Artist" Label. */
	UILabel	*_artist; /*!< @brief Artist name Label. */
	UILabel	*_genreLabel; /*!< @brief "Genre" Label. */
	UILabel	*_genre; /*!< @brief Genre name Label. */
	UILabel	*_titleLabel; /*!< @brief "Title" Label. */
	UILabel	*_title; /*!< @brief Actual title Label. */
	UILabel	*_yearLabel; /*!< @brief "Year" Label. */
	UILabel	*_year; /*!< @brief Label with year. */
}

/*!
 @brief Metadata.
 */
@property (nonatomic, strong) NSObject<MetadataProtocol> *metadata;

/*!
 @brief Coverart.
 */
@property (nonatomic, strong) UIImageView *coverart;

@end
