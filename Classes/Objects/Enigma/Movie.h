//
//  Movie.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "MovieProtocol.h"

/*!
 @brief Movie in Enigma.
 */
@interface EnigmaMovie : NSObject <MovieProtocol>
{
@private
	NSNumber *_length; /*!< @brief Length. */
	NSNumber *_size; /*!< @brief Size. */
	NSArray *_tags; /*!< @brief Tags. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Movie. */
}

/*!
 @brief Standard initializer.
 
 @param CXMLNode Pointer to CXMLNode describing this Movie.
 @return EnigmaMovie instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
