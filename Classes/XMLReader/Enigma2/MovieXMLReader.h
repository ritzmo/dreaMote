//
//  MovieXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "MovieSourceDelegate.h"

/*!
 @brief Enigma2 Movie XML Reader.
 */
@interface Enigma2MovieXMLReader : SaxXmlReader
{
@private
	NSObject<MovieProtocol> *currentMovie; /*!< @brief Current Movie. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return EnigmaMovieXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<MovieSourceDelegate> *)delegate;

@end
