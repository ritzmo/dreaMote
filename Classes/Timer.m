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
#define kDurationElementName @"e2duration"
#define kTitleElementName @"e2name"
#define kDescriptionElementName @"e2description"
#define kJustplayElementName @"e2justplay"
#define kDisabledElementName @"e2disabled"
#define kRepeatedElementName @"e2repeated"

@implementation Timer

@synthesize rawAttributes = _rawAttributes;
@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize duration = _duration;
@synthesize title = _title;
@synthesize description = _description;
@synthesize disabled = _disabled;
@synthesize repeated = _repeated;
@synthesize justplay = _justplay;

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
        childElements = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], kEitElementName, [NSNull null], kBeginElementName, [NSNull null], kDurationElementName, [NSNull null], kTitleElementName, [NSNull null], kDescriptionElementName, [NSNull null], kJustplayElementName, [NSNull null], kDisabledElementName, [NSNull null], kRepeatedElementName, nil];
    }
    return childElements;
}

+ (NSDictionary *)setterMethodsAndChildElementNames
{
    static NSDictionary *propertyNames = nil;
    if (!propertyNames) {
        propertyNames = [[NSDictionary alloc] initWithObjectsAndKeys:@"setEit:", kEitElementName, @"setBegin:", kBeginElementName, @"setDuration:", kDurationElementName, @"setTitle:", kTitleElementName, @"setDescription:", kDescriptionElementName, @"setJustplay:", kJustplayElementName, @"setDisabled:", kDisabledElementName, @"setRepeated:", kRepeatedElementName, nil];
    }
    return propertyNames;
}

@end
