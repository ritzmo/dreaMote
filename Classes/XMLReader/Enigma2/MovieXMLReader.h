//
//  MovieXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "MovieSourceDelegate.h"

/*!
 @brief Enigma2 Movie XML Reader.
 */
@interface Enigma2MovieXMLReader : BaseXMLReader
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
