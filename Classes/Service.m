//
//  Service.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Service.h"

#define kSrefElementName @"e2servicereference"
#define kSnameElementName @"e2servicename"

@implementation Service

@synthesize rawAttributes = _rawAttributes;
@synthesize sref = _sref;
@synthesize sname = _sname;

- (id)initWithService:(Service *)service
{
	self = [super init];
	
	if (self) {
		self.sref = [[service sref] copy];
		self.sname = [[service sname] copy];
	}

	return self;
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithService:self];

	return newElement;
}

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
	return [NSString stringWithFormat:@"<%@> Name: '%@'.\n Ref: '%@'.\n", [self class], self.sname, self.sref];
}

+ (NSDictionary *)childElements
{
	static NSDictionary *childElements = nil;
	if (!childElements) {
		childElements = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], kSrefElementName, [NSNull null], kSnameElementName, nil];
	}
	return childElements;
}

+ (NSDictionary *)setterMethodsAndChildElementNames
{
	static NSDictionary *propertyNames = nil;
	if (!propertyNames) {
		propertyNames = [[NSDictionary alloc] initWithObjectsAndKeys:@"setSref:", kSrefElementName, @"setSname:", kSnameElementName, nil];
	}
	return propertyNames;
}

- (NSString *)getServiceReference
{
	return _sref;
}

- (NSString *)getServiceName
{
	return _sname;
}

@end
