//
//  Service.m
//  dreaMote
//
//  Created by Moritz Venn on 15.12.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "Service.h"

#import <Constants.h>

@implementation NeutrinoService

@synthesize piconName;

- (id)initWithService:(NSObject<ServiceProtocol> *)service
{
	if((self = [super initWithService:service]))
	{
		if([service respondsToSelector:@selector(piconName)])
			self.piconName = [((NeutrinoService *)service).piconName copy];
	}
	return self;
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
		_calculatedPicon = YES;
	}
	return _picon;
}

@end
