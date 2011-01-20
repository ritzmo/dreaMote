//
//  Bouquet.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Bouquet.h"

#import "../Generic/Service.h"
#import "CXMLElement.h"

@implementation NeutrinoBouquet

- (NSString *)sref
{
	return [[_node attributeForName: @"bouquet_id"] stringValue];
}

- (void)setSref: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)sname
{
	return [[_node attributeForName: @"name"] stringValue];
}

- (void)setSname: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (id)initWithNode: (CXMLElement *)node
{
	if((self = [super init]))
	{
		_node = [node retain];
	}
	return self;
}

- (void)dealloc
{
	[_node release];
	[super dealloc];
}

- (BOOL)isValid
{
	return _node && self.sref != nil;
}

- (UIImage *)picon
{
	return nil;
}

- (NSArray *)nodesForXPath: (NSString *)xpath error: (NSError **)error
{
	if(!_node)
		return nil;

	return [_node nodesForXPath: xpath error: error];
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[GenericService alloc] initWithService: self];

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
