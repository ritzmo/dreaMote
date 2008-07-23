//
//  Movie.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Movie : NSObject
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

@property (nonatomic, retain) NSString *sref;
@property (nonatomic, retain) NSString *sname;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sdescription;
@property (nonatomic, retain) NSString *edescription;
@property (nonatomic, retain) NSNumber *length;
@property (nonatomic, retain) NSNumber *size;
@property (nonatomic, retain) NSArray *tags;

- (void)setTimeFromString: (NSString *)newTime;
- (void)setTagsFromString: (NSString *)newTags;


@end
