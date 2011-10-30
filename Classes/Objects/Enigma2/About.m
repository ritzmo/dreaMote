//
//  About.m
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "About.h"

#import "../Generic/Harddisk.h"

#import "CXMLElement.h"

@implementation Enigma2About

- (id)initWithNode:(CXMLNode *)node
{
	if((self = [super init]))
	{
		_hdd = nil;
		_tuners = nil;
		_node = node;
	}
	return self;
}


- (NSString *)version
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2enigmaversion" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (NSString *)imageVersion
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2imageversion" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (NSString *)model
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2model" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (Harddisk *)hdd
{
	if(_hdd != nil) return _hdd;

	const NSArray *resultNodes = [_node nodesForXPath:@"e2hddinfo" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		NSString *model;
		NSString *capacity;
		NSString *free;

		NSArray *childNodes = [resultElement nodesForXPath:@"model" error:nil];
		if(![childNodes count]) break;
		model = [[childNodes objectAtIndex:0] stringValue];
		
		childNodes = [resultElement nodesForXPath:@"capacity" error:nil];
		if(![childNodes count]) break;
		capacity = [[childNodes objectAtIndex:0] stringValue];
		
		childNodes = [resultElement nodesForXPath:@"free" error:nil];
		if(![childNodes count]) break;
		free = [[childNodes objectAtIndex:0] stringValue];

		_hdd = [[Harddisk alloc] initWithModel:model andCapacity:capacity andFree:free];
		break; // only support first hdd for now
	}
	return _hdd;
}

- (NSArray *)tuners
{
	if(_tuners != nil) return _tuners;

	_tuners = [NSMutableArray arrayWithCapacity: 4];
	const NSArray *resultNodes = [_node nodesForXPath:@"e2tunerinfo/e2nim/type" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		[_tuners addObject:[resultElement stringValue]];
	}
	return _tuners;
}

- (NSString *)sname
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2servicename" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

@end
