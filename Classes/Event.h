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
	NSCalendarDate *_begin;
	NSCalendarDate *_end;
	NSString *_title;
	NSString *_sdescription;
	NSString *_edescription;
}

@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSCalendarDate *begin;
@property (nonatomic, retain) NSCalendarDate *end;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sdescription;
@property (nonatomic, retain) NSString *edescription;

- (void)setBeginFromString: (NSString *)newBegin;
- (void)setEndFromDurationString: (NSString *)newDuration;

@end
