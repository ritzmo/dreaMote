//
//  AutoTimer.h
//  dreaMote
//
//  Created by Moritz Venn on 18.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../TimerProtocol.h"

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
	NSString *name;
	NSString *match;
	BOOL enabled;
	NSInteger idno;
	NSDate *from;
	NSDate *to;
	NSInteger offsetBefore;
	NSInteger offsetAfter;
	NSString *encoding;
	autoTimerSearchType searchType;
	autoTimerSearchCase searchCase;
	BOOL overrideAlternatives;
	NSMutableArray *services;
	NSMutableArray *bouquets;
	NSArray *tags;
	NSMutableArray *includeTitle;
	NSMutableArray *includeShortdescription;
	NSMutableArray *includeDescription;
	NSMutableArray *includeDayOfWeek;
	NSMutableArray *excludeTitle;
	NSMutableArray *excludeShortdescription;
	NSMutableArray *excludeDescription;
	NSMutableArray *excludeDayOfWeek;
	NSInteger maxduration;
	NSString *location;
	BOOL justplay;
	NSDate *before;
	NSDate *after;
	autoTimerAvoidDuplicateDescription avoidDuplicateDescription;
	enum afterEvent afterEventAction; // TODO: support extended syntax
	// TODO: add counter
}

+ (AutoTimer *)timer;
- (void)addInclude:(NSString *)include where:(autoTimerWhereType)where;
- (void)addExclude:(NSString *)exclude where:(autoTimerWhereType)where;

@property (nonatomic, readonly) BOOL valid;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *match;
@property (nonatomic) BOOL enabled;
@property (nonatomic) NSInteger idno;
@property (nonatomic, retain) NSDate *from;
@property (nonatomic, retain) NSDate *to;
@property (nonatomic) NSInteger offsetBefore;
@property (nonatomic) NSInteger offsetAfter;
@property (nonatomic, retain) NSString *encoding;
@property (nonatomic) autoTimerSearchType searchType;
@property (nonatomic) autoTimerSearchCase searchCase;
@property (nonatomic) BOOL overrideAlternatives;
@property (nonatomic, retain) NSMutableArray *services;
@property (nonatomic, retain) NSMutableArray *bouquets;
@property (nonatomic, retain) NSArray *tags;
@property (nonatomic, readonly) NSMutableArray *includeTitle;
@property (nonatomic, readonly) NSMutableArray *includeShortdescription;
@property (nonatomic, readonly) NSMutableArray *includeDescription;
@property (nonatomic, readonly) NSMutableArray *includeDayOfWeek;
@property (nonatomic, readonly) NSMutableArray *excludeTitle;
@property (nonatomic, readonly) NSMutableArray *excludeShortdescription;
@property (nonatomic, readonly) NSMutableArray *excludeDescription;
@property (nonatomic, readonly) NSMutableArray *excludeDayOfWeek;
@property (nonatomic) NSInteger maxduration;
@property (nonatomic, retain) NSString *location;
@property (nonatomic) BOOL justplay;
@property (nonatomic, retain) NSDate *before;
@property (nonatomic, retain) NSDate *after;
@property (nonatomic) autoTimerAvoidDuplicateDescription avoidDuplicateDescription;
@property (nonatomic) enum afterEvent afterEventAction;

@end
