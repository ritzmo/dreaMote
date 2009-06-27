//
//  MovieXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "MovieSourceDelegate.h"

/*!
 @brief Enigma Movie XML Reader.
 */
@interface EnigmaMovieXMLReader : BaseXMLReader
{
@private
	NSObject<MovieSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaMovieXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<MovieSourceDelegate> *)delegate;

@end
