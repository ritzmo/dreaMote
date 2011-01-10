//
//  Metadata.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MetadataProtocol.h"

/*!
 @brief Metadata independent of connector.
 */
@interface GenericMetadata : NSObject<MetadataProtocol>
{
@private
	NSString *title;
	NSString *artist;
	NSString *album;
	NSString *genre;
	NSString *year;
	NSString *coverpath;
}

/*!
 @brief Init with existing information.
 
 @note Required to create a copy.
 @param event Metadata to copy.
 @return Metadata instance.
 */
- (id)initWithMetadata: (NSObject<MetadataProtocol> *)meta;

@end
