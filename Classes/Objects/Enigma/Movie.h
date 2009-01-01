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

@interface EnigmaMovie : NSObject <MovieProtocol>
{
@private	
	NSString *_sref;
	NSString *_title;
	NSNumber *_length;
	NSNumber *_size;
	NSArray *_tags;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
