//
//  Volume.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Volume.h"

#define kResultElementName		@"e2result"
#define kResultTextElementName	@"e2resulttext"
#define kCurrentElementName		@"e2current"
#define kIsMutedElementName		@"e2ismuted"

@implementation Volume

@synthesize rawAttributes = _rawAttributes;
@synthesize result = _result;
@synthesize resulttext = _resulttext;
@synthesize current = _current;
@synthesize ismuted = _ismuted;

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
    return [NSString stringWithFormat:@"<%@> ResultText: '%@'.\n Current: '%@'.\n Is muted: '%@'.\n", [self class], self.resulttext, self.current, self.ismuted];
}

+ (NSDictionary *)childElements
{
    static NSDictionary *childElements = nil;
    if (!childElements) {
        childElements = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], kResultElementName, [NSNull null], kResultTextElementName, [NSNull null], kCurrentElementName, [NSNull null], kIsMutedElementName, nil];
    }
    return childElements;
}

+ (NSDictionary *)setterMethodsAndChildElementNames
{
    static NSDictionary *propertyNames = nil;
    if (!propertyNames) {
        propertyNames = [[NSDictionary alloc] initWithObjectsAndKeys:@"setResult:", kResultElementName, @"setResulttext:", kResultTextElementName, @"setCurrent:", kCurrentElementName, @"setIsmuted:", kIsMutedElementName, nil];
    }
    return propertyNames;
}

@end
