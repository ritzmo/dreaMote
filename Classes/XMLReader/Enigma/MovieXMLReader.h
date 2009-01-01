//
//  MovieXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"

@interface EnigmaMovieXMLReader : BaseXMLReader
{
}

+ (EnigmaMovieXMLReader*)initWithTarget:(id)target action:(SEL)action;

@end
