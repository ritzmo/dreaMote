//
//  EPGRefreshSettings.h
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPGRefreshSettings : NSObject
{
@private
    BOOL enabled;
	NSDate *begin;
	NSDate *end;
	NSInteger interval;
	NSInteger delay_standby;
	BOOL inherit_autotimer;
	BOOL afterevent;
	BOOL force;
	BOOL wakeup;
	BOOL parse_autotimer;
	NSString *adapter;
	BOOL canDoBackgroundRefresh;
	BOOL hasAutoTimer;
}

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, assign) NSInteger interval;
@property (nonatomic, assign) NSInteger delay_standby;
@property (nonatomic, assign) BOOL inherit_autotimer;
@property (nonatomic, assign) BOOL afterevent;
@property (nonatomic, assign) BOOL force;
@property (nonatomic, assign) BOOL wakeup;
@property (nonatomic, assign) BOOL parse_autotimer;
@property (nonatomic, retain) NSString *adapter;
@property (nonatomic, assign) BOOL canDoBackgroundRefresh;
@property (nonatomic, assign) BOOL hasAutoTimer;

@end
