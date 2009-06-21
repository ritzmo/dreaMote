//
//  Movie.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "MovieProtocol.h"

/*!
 @brief Movie in Enigma2.
 */
@interface Enigma2Movie : NSObject <MovieProtocol>
{
@private
	NSArray *_tags; /*!< @brief Tags. */
	NSNumber *_length; /*!< @brief Length. */
	NSDate *_time; /*!< @brief Begin. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Movie. */
}


/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Movie.
 @return Enigma2Movie instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
