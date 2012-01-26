//
//  Result.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.10.
//  Copyright 2010-2012 Moritz Venn. All rights reserved.
//

#import "Result.h"

@implementation Result

@synthesize result, resulttext;

+(Result *)createResult
{
	Result *result = [[Result alloc] init];
	return result;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> ResultText: '%@'.\nResult: '%@'\n", [self class], self.resulttext, self.result ? @"YES" : @"NO"];
}

- (void)setResultFromString: (NSString *)newResult
{
	result = [newResult isEqualToString:@"True"];
}

@end
