//
//  Service.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Service.h"

#import "Constants.h"

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
	[_picon release];

	[super dealloc];
}

- (BOOL)isValid
{
	return _sref != nil;
}

- (UIImage *)picon
{
	if(!_calculatedPicon)
	{
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

		_calculatedPicon = YES;
	}
	return _picon;
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
