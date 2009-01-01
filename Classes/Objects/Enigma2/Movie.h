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

@interface Enigma2Movie : NSObject <MovieProtocol>
{
@private
	NSArray *_tags;
	NSNumber *_length;
	NSDate *_time;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
