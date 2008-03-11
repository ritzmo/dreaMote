//
//  Timer.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Timer.h"

#define kEitElementName @"e2eit"
#define kBeginElementName @"e2timebegin"
#define kEndElementName @"e2timeend"
#define kTitleElementName @"e2name"
#define kDescriptionElementName @"e2description"
#define kJustplayElementName @"e2justplay"
#define kDisabledElementName @"e2disabled"
#define kRepeatedElementName @"e2repeated"
#define kSrefElementName @"e2servicereference"
#define kSnameElementName @"e2servicename"

@implementation Timer

@synthesize rawAttributes = _rawAttributes;
@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize tdescription = _tdescription;
@synthesize disabled = _disabled;
@synthesize repeated = _repeated;
@synthesize justplay = _justplay;
@synthesize service = _service;
@synthesize sref = _sref;

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
        childElements = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], kEitElementName, [NSNull null], kBeginElementName, [NSNull null], kEndElementName, [NSNull null], kTitleElementName, [NSNull null], kDescriptionElementName, [NSNull null], kJustplayElementName, [NSNull null], kDisabledElementName, [NSNull null], kRepeatedElementName, [NSNull null], kSrefElementName, [NSNull null], kSnameElementName, nil];
    }
    return childElements;
}

+ (NSDictionary *)setterMethodsAndChildElementNames
{
    static NSDictionary *propertyNames = nil;
    if (!propertyNames) {
        propertyNames = [[NSDictionary alloc] initWithObjectsAndKeys:@"setEit:", kEitElementName, @"setBeginFromString:", kBeginElementName, @"setEndFromString:", kEndElementName, @"setTitle:", kTitleElementName, @"setTdescription:", kDescriptionElementName, @"setJustplayFromString:", kJustplayElementName, @"setDisabledFromString:", kDisabledElementName, @"setRepeatedFromString:", kRepeatedElementName, @"setSref:", kSrefElementName, @"setServiceFromSname:", kSnameElementName, nil];
    }
    return propertyNames;
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[_begin release];
	_begin = [[NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]] retain];
}

- (void)setEndFromString: (NSString *)newEnd
{
	[_end release];
	_end = [[NSDate dateWithTimeIntervalSince1970: [newEnd doubleValue]] retain];
}

- (void)setDisabledFromString: (NSString *)newDisabled
{
	_disabled = [newDisabled isEqualToString: @"1"];
}

- (void)setJustplayFromString: (NSString *)newJustplay
{
	_justplay = [newJustplay isEqualToString: @"1"];
}

- (void)setRepeatedFromString: (NSString *)newRepeated
{
	_repeated = [newRepeated intValue];
}

- (void)setServiceFromSname: (NSString *)newSname
{
	[_service release];
	_service = [[Service alloc] init];
	_service.sref = _sref;
	_service.sname = newSname;
}

@end
