//
//  MetadataProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Protocol of (audio) Metadata.
 */
@protocol MetadataProtocol

/*!
 @brief title.
 */
@property (nonatomic, strong) NSString *title;

/*!
 @brief artist.
 */
@property (nonatomic, strong) NSString *artist;

/*!
 @brief album.
 */
@property (nonatomic, strong) NSString *album;

/*!
 @brief genre.
 */
@property (nonatomic, strong) NSString *genre;

/*!
 @brief year.
 */
@property (nonatomic, strong) NSString *year;

/*!
 @brief Full path to cover.
 */
@property (nonatomic, strong) NSString *coverpath;

/*!
 @brief Valid or fake metadata.
 */
@property (nonatomic, readonly, getter = isValid) BOOL valid;

@end
