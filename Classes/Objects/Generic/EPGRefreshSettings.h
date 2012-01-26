//
//  EPGRefreshSettings.h
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPGRefreshSettings : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) NSDate *begin;
@property (nonatomic, strong) NSDate *end;
@property (nonatomic, assign) BOOL interval_in_seconds;
@property (nonatomic, assign) NSInteger interval;
@property (nonatomic, assign) NSInteger delay_standby;
@property (nonatomic, assign) NSInteger lastscan;
@property (nonatomic, assign) BOOL inherit_autotimer;
@property (nonatomic, assign) BOOL afterevent;
@property (nonatomic, assign) BOOL force;
@property (nonatomic, assign) BOOL wakeup;
@property (nonatomic, assign) BOOL parse_autotimer;
@property (nonatomic, strong) NSString *adapter;
@property (nonatomic, assign) BOOL canDoBackgroundRefresh;
@property (nonatomic, assign) BOOL hasAutoTimer;

@end
