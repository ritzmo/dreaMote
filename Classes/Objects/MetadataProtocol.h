//
//  MetadataProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Protocol of (audio) Metadata.
 */
@protocol MetadataProtocol

/*!
 @brief title.
 */
@property (nonatomic, retain) NSString *title;

/*!
 @brief artist.
 */
@property (nonatomic, retain) NSString *artist;

/*!
 @brief album.
 */
@property (nonatomic, retain) NSString *album;

/*!
 @brief genre.
 */
@property (nonatomic, retain) NSString *genre;

/*!
 @brief year.
 */
@property (nonatomic, retain) NSString *year;

/*!
 @brief Full path to cover.
 */
@property (nonatomic, retain) NSString *coverpath;

/*!
 @brief Valid or fake metadata.
 */
@property (nonatomic, readonly, getter = isValid) BOOL valid;

@end
