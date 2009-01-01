//
//  MovieProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MovieProtocol

@property (nonatomic, retain) NSString *sref;
@property (nonatomic, retain) NSString *sname;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sdescription;
@property (nonatomic, retain) NSString *edescription;
@property (nonatomic, retain) NSNumber *length;
@property (nonatomic, retain) NSNumber *size;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, readonly, getter = isValid) BOOL valid;

- (void)setTimeFromString: (NSString *)newTime;
- (void)setTagsFromString: (NSString *)newTags;

@end
