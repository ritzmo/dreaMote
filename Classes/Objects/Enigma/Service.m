//
//  Service.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Service.h"

#import "Constants.h"
#import "../Generic/Service.h"
#import "CXMLElement.h"

@implementation EnigmaService

- (NSString *)sref
{
	const NSArray *resultNodes = [_node nodesForXPath:@"reference" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSref: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)sname
{
	// TODO: how can this possibly crash?
	const NSArray *resultNodes = [_node nodesForXPath:@"name" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSname: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)piconName
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
	return nil;
}

- (void)setPiconName:(NSString *)piconName
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (id)initWithNode: (CXMLNode *)node
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
	// XXX: naming convention is off in this method (local variables starting with _), but easier to copy code this way
	UIImage *_picon = nil;
	if(IS_IPAD())
	{
		const NSString *_sref = self.sref;
		const NSInteger length = [_sref length]+1;
		char *sref = malloc(length);
		if(!sref)
			return nil;
		if(![_sref getCString:sref maxLength:length encoding:NSASCIIStringEncoding])
			return nil;
		NSInteger i = length-1;
		BOOL first = YES;
		for(; i > 0; --i)
		{
			if(sref[i] == ':')
			{
				if(first)
				{
					sref[i] = '\0';
					first = NO;
				}
				else
					sref[i] = '_';
			}
		}
		NSString *basename = [[NSString alloc] initWithBytesNoCopy:sref length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
		NSString *piconName = [[NSString alloc] initWithFormat:kPiconPath, basename];
		_picon = [[UIImage imageNamed:[piconName stringByExpandingTildeInPath]] retain];
		[basename release]; // also frees sref
		[piconName release];
	}
	return _picon;
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
