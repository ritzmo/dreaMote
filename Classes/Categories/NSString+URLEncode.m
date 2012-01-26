//
//  NSString+URLEncode.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)

- (NSString *)urlencode
{
	return [self urlencodeWithEncoding:NSUTF8StringEncoding];
}

- (NSString *)urlencodeWithEncoding:(NSStringEncoding)stringEncoding
{
	NSString *escaped = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																			(__bridge CFStringRef)self,
																			NULL,
																			(CFStringRef)@"&+,/:;=?@ \t#<>\"\n",
																			CFStringConvertNSStringEncodingToEncoding(stringEncoding)
																			);
	return escaped;
}

@end
