//
//  Event.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Event : NSObject
{
@private	
	NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	NSString *_title;
	NSString *_sdescription;
	NSString *_edescription;
}

@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sdescription;
@property (nonatomic, retain) NSString *edescription;

- (void)setBeginFromString: (NSString *)newBegin;
- (void)setEndFromDurationString: (NSString *)newDuration;

@end
