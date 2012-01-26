//
//  MovieXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/MovieSourceDelegate.h>

/*!
 @brief Enigma Movie XML Reader.
 */
@interface EnigmaMovieXMLReader : SaxXmlReader
{
@private
	NSUInteger count; /*!< @brief Counter. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaMovieXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<MovieSourceDelegate> *)delegate;

@end
