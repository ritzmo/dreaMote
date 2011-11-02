//
//  AutoTimer.h
//  dreaMote
//
//  Created by Moritz Venn on 18.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Objects/EventProtocol.h>
#import <Objects/TimerProtocol.h>

typedef enum
{
	SEARCH_TYPE_EXACT,
	SEARCH_TYPE_PARTIAL,
} autoTimerSearchType;

typedef enum
{
	CASE_SENSITIVE,
	CASE_INSENSITIVE,
} autoTimerSearchCase;

typedef enum
{
	autoTimerWhereInvalid = -1,
	autoTimerWhereTitle = 0,
	autoTimerWhereShortdescription = 1,
	autoTimerWhereDescription = 2,
	autoTimerWhereDayOfWeek = 3,
} autoTimerWhereType;

typedef enum
{
	autoTimerAddNone = 0,
	autoTimerAddSameService = 1,
	autoTimerAddAnyService = 2,
	autoTimerAddRecording = 3,
} autoTimerAvoidDuplicateDescription;

@interface AutoTimer : NSObject
{
@private
	NSMutableArray *includeTitle;
	NSMutableArray *includeShortdescription;
	NSMutableArray *includeDescription;
	NSMutableArray *includeDayOfWeek;
	NSMutableArray *excludeTitle;
	NSMutableArray *excludeShortdescription;
	NSMutableArray *excludeDescription;
	NSMutableArray *excludeDayOfWeek;
	enum afterEvent afterEventAction; // TODO: support extended syntax
	// TODO: add counter
}

+ (AutoTimer *)timer;
+ (AutoTimer *)timerFromEvent:(NSObject<EventProtocol> *)event;
- (void)addInclude:(NSString *)include where:(autoTimerWhereType)where;
- (void)addExclude:(NSString *)exclude where:(autoTimerWhereType)where;

@property (nonatomic, readonly) BOOL valid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *match;
@property (nonatomic) BOOL enabled;
@property (nonatomic) NSInteger idno;
@property (nonatomic, strong) NSDate *from;
@property (nonatomic, strong) NSDate *to;
@property (nonatomic) NSInteger offsetBefore;
@property (nonatomic) NSInteger offsetAfter;
@property (nonatomic, strong) NSString *encoding;
@property (nonatomic) autoTimerSearchType searchType;
@property (nonatomic) autoTimerSearchCase searchCase;
@property (nonatomic) BOOL overrideAlternatives;
@property (nonatomic, strong) NSMutableArray *services;
@property (nonatomic, strong) NSMutableArray *bouquets;
@property (nonatomic, strong) NSArray *tags;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *includeTitle;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *includeShortdescription;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *includeDescription;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *includeDayOfWeek;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *excludeTitle;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *excludeShortdescription;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *excludeDescription;
@property (unsafe_unretained, nonatomic, readonly) NSMutableArray *excludeDayOfWeek;
@property (nonatomic) NSInteger maxduration;
@property (nonatomic, strong) NSString *location;
@property (nonatomic) BOOL justplay;
@property (nonatomic, strong) NSDate *before;
@property (nonatomic, strong) NSDate *after;
@property (nonatomic) autoTimerAvoidDuplicateDescription avoidDuplicateDescription;
@property (nonatomic) enum afterEvent afterEventAction;

@end
