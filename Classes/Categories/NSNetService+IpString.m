//
//  NSNetService+IpString.m
//  dreaMote
//
//  Created by Moritz Venn on 24.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "NSNetService+IpString.h"

#include <arpa/inet.h>

@implementation NSNetService(IpString)

- (NSString *)ipAddress
{
	for(NSData *data in [self addresses])
	{
		char addressBuffer[100];
		struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
		int sockFamily = socketAddress->sin_family;

		if(sockFamily == AF_INET || sockFamily == AF_INET6)
		{
			const char* addressStr = inet_ntop(sockFamily,
											   &(socketAddress->sin_addr), addressBuffer,
											   sizeof(addressBuffer));

			if(addressStr)
				return [[[NSString alloc] initWithCString:addressStr encoding:NSASCIIStringEncoding] autorelease];
			
		}
	}
	return nil;
}

@end
