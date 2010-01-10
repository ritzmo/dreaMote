//
//  Result.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.10.
//  Copyright 2010 Moritz Venn. All rights reserved.
//

#import "Result.h"

@implementation Result

@synthesize result = _result;
@synthesize resulttext = _resulttext;

+(Result *)createResult
{
	Result *result = [[Result alloc] init];
	return [result autorelease];
}

- (void)dealloc
{
	[_resulttext release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> ResultText: '%@'.\nResult: '%@'\n", [self class], self.resulttext, self.result ? @"YES" : @"NO"];
}

- (void)setResultFromString: (NSString *)newResult
{
	_result = [newResult isEqualToString: @"True"];
}

@end
