//
//  MovieXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Movie.h"
#import "BaseXMLReader.h"

@interface MovieXMLReader : BaseXMLReader
{
@private
	Movie *_currentMovieObject;
}

+ (MovieXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Movie *currentMovieObject;

@end
