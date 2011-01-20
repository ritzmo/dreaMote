//
//  Service.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Service.h"

@implementation GenericService

@synthesize sref = _sref;
@synthesize sname = _sname;

- (id)initWithService:(NSObject<ServiceProtocol> *)service
{
	if((self = [super init]))
	{
		_sref = [service.sref copy];
		_sname = [service.sname copy];
	}

	return self;
}

- (void)dealloc
{
	[_sref release];
	[_sname release];

	[super dealloc];
}

- (BOOL)isValid
{
	return _sref != nil;
}

- (UIImage *)picon
{
	NSRange range = [_sref rangeOfString:@":" options:NSBackwardsSearch];
	NSString *cleanName = [_sref substringToIndex:range.location];
	UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"Documents/%@.png", [cleanName stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
	if(!image)
		image = [UIImage imageNamed:[NSString stringWithFormat:@"Documents/%@.png", _sname]];
	return image;
}

- (NSArray *)nodesForXPath: (NSString *)xpath error: (NSError **)error
{
	return nil;
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithService:self];

	return newElement;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Name: '%@'.\n Ref: '%@'.\n", [self class], self.sname, self.sref];
}

- (BOOL)isEqualToService: (NSObject<ServiceProtocol> *)otherService
{
	return [self.sref isEqualToString: otherService.sref] &&
	[self.sname isEqualToString: otherService.sname];
}

@end
