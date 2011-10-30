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

@synthesize sname = _sname;
@synthesize piconName = _piconName;

- (id)initWithService:(NSObject<ServiceProtocol> *)service
{
	if((self = [super init]))
	{
		_sref = [service.sref copy];
		_sname = [service.sname copy];
		_valid = service.valid;
		_piconName = [service.piconName copy];
	}

	return self;
}


- (NSString *)sref
{
	return _sref;
}

- (void)setSref:(NSString *)sref
{
	if(sref == _sref) return;
	SafeRetainAssign(_sref, sref);
	_valid = YES;
}

- (BOOL)isValid
{
	return _valid;
}

- (void)setValid:(BOOL)newValid
{
	_valid = newValid;
}

- (UIImage *)picon
{
	if(!_calculatedPicon)
	{
		if(_piconName)
		{
			NSRange piconRange = [_piconName rangeOfString:@"/" options:NSBackwardsSearch];
			if(piconRange.location != NSNotFound)
			{
				piconRange.length = [_piconName length] - piconRange.location - 1;
				piconRange.location += 1;
				NSString *basename = [_piconName substringWithRange:piconRange];
				NSString *piconName = [[NSString alloc] initWithFormat:kPiconPath, basename];
				_picon = [UIImage imageNamed:piconName];
			}
		}
		else
		{
			NSInteger length = [_sref length]+1;
			char *sref = malloc(length);
			if(!sref)
				return nil;
			if(![_sref getCString:sref maxLength:length encoding:NSASCIIStringEncoding])
			{
				free(sref);
				return nil;
			}
			NSInteger i = length-2;
			/*!
			 @note Enigma sref needs at least 20 characters, so if we did not find the first ':'
			 at the 19th position, abort early.
			 */
			for(; i > 18; --i)
			{
				if(sref[i] == ':')
				{
					// rstrip(':')
					do
					{
						length = i;
						sref[i] = '\0';
						--i;
					} while(sref[i] == ':');

					// skip one character from last ':'
					for(--i; i > 0; --i)
					{
						if(sref[i] == ':')
						{
							sref[i] = '_';
							--i; // there has to be at least one character != ':' before this one
						}
					}
					break;
				}
			}
			NSString *basename = [[NSString alloc] initWithBytesNoCopy:sref length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
			NSString *piconName = [[NSString alloc] initWithFormat:kPiconPathPng, basename];
			_picon = [UIImage imageNamed:piconName];
			 // also frees sref
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
