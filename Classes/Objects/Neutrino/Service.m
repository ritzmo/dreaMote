//
//  Service.m
//  dreaMote
//
//  Created by Moritz Venn on 11.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Service.h"

#import "Constants.h"
#import "../Generic/Service.h"
#import "CXMLElement.h"

@implementation NeutrinoService

- (NSString *)sref
{
	if(!_sref)
	{
		const NSString *s = [[_node attributeForName:@"s"] stringValue];
		if(s && ![s isEqualToString:@""])
			_sref = [[NSString stringWithFormat:@"%@%@%@%@",
					s,
					[[_node attributeForName:@"t"] stringValue],
					[[_node attributeForName:@"on"] stringValue],
					[[_node attributeForName:@"i"] stringValue]] retain];
		else
			_sref = [[NSString stringWithFormat:@"%@%@%@",
					[[_node attributeForName:@"tsid"] stringValue],
					[[_node attributeForName:@"onid"] stringValue],
					[[_node attributeForName:@"serviceID"] stringValue]] retain];
	}
	return _sref;
}

- (void)setSref: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)sname
{
	if(!_sname)
	{
		const NSString *n = [[_node attributeForName:@"n"] stringValue];
		if(n && ![n isEqualToString:@""])
			_sname = [n retain];
		else
			_sname = [[_node attributeForName:@"name"] stringValue];
	}
	return _sname;
}

- (void)setSname: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
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
	[_sname release];
	[_sref release];

	[super dealloc];
}

- (BOOL)isValid
{
	return _node != nil;
}

- (UIImage *)picon
{
	UIImage *picon = nil;
	if(IS_IPAD())
	{
		NSString *piconName = [[NSString alloc] initWithFormat:kPiconPath, self.sname];
		picon = [UIImage imageNamed:[piconName stringByExpandingTildeInPath]];
		[piconName release];
	}
	return picon;
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
