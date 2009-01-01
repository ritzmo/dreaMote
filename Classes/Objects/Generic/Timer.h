//
//  Timer.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EventProtocol.h"
#import "TimerProtocol.h"

@interface Timer : NSObject <TimerProtocol>
{
@private
	NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	BOOL _disabled;
	NSString *_title;
	NSString *_tdescription;
	NSInteger _repeated;
	NSInteger _repeatcount;
	BOOL _justplay;
	Service *_service;
	NSString *_sref;
	NSString *_sname;
	NSInteger _state;
	NSInteger _afterevent;
	double _duration;
	BOOL _isValid;
	NSString *_timeString;
}

+ (Timer *)withEvent: (NSObject<EventProtocol> *)ourEvent;
+ (Timer *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (Service *)ourService;
+ (Timer *)timer;

@end
