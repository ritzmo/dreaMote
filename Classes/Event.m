//
//  Event.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

#define kEitElementName @"e2eventid"
#define kBeginElementName @"e2eventstart"
#define kDurationElementName @"e2eventduration"
#define kTitleElementName @"e2eventtitle"
#define kDescriptionElementName @"e2eventdescription"
#define kExtendedElementName @"e2eventdescriptionextended"

@implementation Event

@synthesize rawAttributes = _rawAttributes;
@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;

- (NSMutableDictionary *)XMLAttributes
{
	return self.rawAttributes;
}

- (void)setXMLAttributes:(NSMutableDictionary *)attributes
{
	self.rawAttributes = attributes;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

+ (NSDictionary *)childElements
{
	static NSDictionary *childElements = nil;
	if (!childElements) {
		childElements = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], kEitElementName, [NSNull null], kBeginElementName, [NSNull null], kDurationElementName, [NSNull null], kTitleElementName, [NSNull null], kDescriptionElementName, [NSNull null], kExtendedElementName, nil];
	}
	return childElements;
}

+ (NSDictionary *)setterMethodsAndChildElementNames
{
	static NSDictionary *propertyNames = nil;
	if (!propertyNames) {
		propertyNames = [[NSDictionary alloc] initWithObjectsAndKeys:@"setEit:", kEitElementName, @"setBeginFromString:", kBeginElementName, @"setEndFromDurationString:", kDurationElementName, @"setTitle:", kTitleElementName, @"setSdescription:", kDescriptionElementName, @"setEdescription:", kExtendedElementName, nil];
	}
	return propertyNames;
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[_begin release];
	_begin = [[NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]] retain];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[_end release];
	_end = [[_begin addTimeInterval: [newDuration doubleValue]] retain];
}

@end
