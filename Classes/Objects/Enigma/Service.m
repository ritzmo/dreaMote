//
//  Service.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Service.h"

#import <Constants.h>

@implementation EnigmaService

@synthesize isBouquet;

- (id)initWithService:(NSObject<ServiceProtocol> *)service
{
	if((self = [super initWithService:service]))
	{
		if([service respondsToSelector:@selector(isBouquet)])
			isBouquet = ((EnigmaService *)service).isBouquet;
	}
	return self;
}

@end
