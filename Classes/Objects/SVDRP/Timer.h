//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 04.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EventProtocol.h"
#import "TimerProtocol.h"
#import "ServiceProtocol.h"

@interface SVDRPTimer : NSObject <TimerProtocol>
{
@private
	NSString *_auxiliary;
	NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	NSString *_file;
	NSInteger _flags;
	BOOL _disabled;
	NSString *_title;
	NSString *_tdescription;
	NSString *_repeat;
	NSInteger _repeated;
    NSInteger _repeatcount;
	BOOL _justplay;
	NSString *_lifetime;
	NSString *_priority;
	NSObject<ServiceProtocol> *_service;
	NSString *_sref;
	NSString *_sname;
	NSInteger _state;
	NSInteger _afterevent;
	BOOL _isValid;
	NSString *_timeString;
	NSString *_tid;
	BOOL _hasRepeatBegin;
}

- (NSString *)toString;

@property (nonatomic, retain) NSString *auxiliary;
@property (nonatomic, retain) NSString *lifetime;
@property (nonatomic, retain) NSString *file;
@property (nonatomic) NSInteger flags;
@property (nonatomic) BOOL hasRepeatBegin;
@property (nonatomic, retain) NSString *repeat;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic, retain) NSString *tid;

@end
