//
//  Movie.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MovieProtocol.h"

/*!
 @brief Generic Movie.
 */
@interface GenericMovie : NSObject <MovieProtocol>
{
@private	
	NSString *_sref; /*!< @brief Service Reference. */
	NSString *_sname; /*!< @brief Service Name. */
	NSDate *_time; /*!< @brief Begin. */
	NSString *_title; /*!< @brief Title. */
	NSString *_sdescription; /*!< @brief Short Description. */
	NSString *_edescription; /*!< @brief Extended Description. */
	NSNumber *_length; /*!< @brief Length. */
	NSString *_name; /*!< @brief Filename. */
	NSNumber *_size; /*!< @brief Filesize. */
	NSArray *_tags; /*!< @brief Tags. */
}

@end
