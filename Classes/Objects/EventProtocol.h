//
//  EventProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EventProtocol

@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sdescription;
@property (nonatomic, retain) NSString *edescription;
@property (nonatomic, retain) NSString *timeString;

- (void)setBeginFromString: (NSString *)newBegin;
- (void)setEndFromDurationString: (NSString *)newDuration;

@end
