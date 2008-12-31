//
//  Movie.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MovieProtocol.h"

@interface Movie : NSObject <MovieProtocol>
{
@private	
	NSString *_sref;
	NSString *_sname;
	NSDate *_time;
	NSString *_title;
	NSString *_sdescription;
	NSString *_edescription;
	NSNumber *_length;
	NSNumber *_size;
	NSArray *_tags;
}

@end
