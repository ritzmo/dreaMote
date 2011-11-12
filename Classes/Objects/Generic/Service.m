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

@synthesize sname, sref, piconName;

- (id)init
{
	if((self = [super init]))
	{
		_valid = YES;
	}
	return self;
}

- (id)initWithService:(NSObject<ServiceProtocol> *)service
{
	if((self = [self init]))
	{
		self.sref = [service.sref copy];
		self.sname = [service.sname copy];
		_valid = service.valid;
		self.piconName = [service.piconName copy];
	}

	return self;
}

- (BOOL)isValid
{
	return _valid;
}

- (void)setValid:(BOOL)newValid
{
	_valid = newValid;
}

- (BOOL)piconLoaded
{
	return _calculatedPicon;
}

- (UIImage *)picon
{
	if(!_calculatedPicon && _valid)
	{
		if(self.piconName)
		{
			NSRange piconRange = [self.piconName rangeOfString:@"/" options:NSBackwardsSearch];
			if(piconRange.location != NSNotFound)
			{
				piconRange.length = [self.piconName length] - piconRange.location - 1;
				piconRange.location += 1;
				NSString *basename = [self.piconName substringWithRange:piconRange];
				NSString *fullpath = [[NSString alloc] initWithFormat:kPiconPath, basename];
				_picon = [UIImage imageNamed:fullpath];
			}
		}
		else
		{
			NSInteger length = [self.sref length]+1;
			char *cSref = malloc(length);
			if(!cSref)
				return nil;
			if(![self.sref getCString:cSref maxLength:length encoding:NSASCIIStringEncoding])
			{
				free(cSref);
				return nil;
			}
			NSInteger i = length-2;
			/*!
			 @note Enigma sref needs at least 20 characters, so if we did not find the first ':'
			 at the 19th position, abort early.
			 */
			for(; i > 18; --i)
			{
				if(cSref[i] == ':')
				{
					// rstrip(':')
					do
					{
						length = i;
						cSref[i] = '\0';
						--i;
					} while(cSref[i] == ':');

					// skip one character from last ':'
					for(--i; i > 0; --i)
					{
						if(cSref[i] == ':')
						{
							cSref[i] = '_';
							--i; // there has to be at least one character != ':' before this one
						}
					}
					break;
				}
			}
			NSString *basename = [[NSString alloc] initWithBytesNoCopy:cSref length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
			NSString *fullpath = [[NSString alloc] initWithFormat:kPiconPathPng, basename];
			_picon = [UIImage imageNamed:fullpath];
		}

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
