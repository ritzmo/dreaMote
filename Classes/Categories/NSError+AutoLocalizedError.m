//
//  NSError+AutoLocalizedError.m
//  dreaMote
//
//  Created by Moritz Venn on 27.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "NSError+AutoLocalizedError.h"


@implementation NSError (AutoLocalizedError)

- (NSString *)localizedDescription
{
	NSString *message = nil;
	NSString *domain = [self domain];
	NSInteger code = [self code];

	// assign custom messages
	if(domain == NSURLErrorDomain)
	{
		if(code == NSURLErrorUserCancelledAuthentication)
		{
			message = NSLocalizedString(@"Unable to authenticate. Wrong password?", @"Connection failed due to improper authentication");
		}
	}

	// no custom message, check dict
	if(!message)
		message = [[self userInfo] objectForKey:NSLocalizedDescriptionKey];
	// no message at all, build default
	if(!message)
		message = [NSString stringWithFormat:@"The operation couldn't be completed. (%@ error %d.)", domain, code];

	return message;
}

@end
