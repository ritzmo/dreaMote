//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "Timer.h"

#import "CXMLElement.h"

#import "../Generic/Service.h"

@implementation Enigma2Timer

@synthesize valid = _isValid;
@synthesize timeString = _timeString;

- (NSInteger)repeatcount
{
	return 0;
}

- (void)setRepeatcount: (NSInteger)new
{
	return;
}

- (NSString *)tdescription
{
	if(_tdescription == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2description" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.tdescription = [currentChild stringValue];
			break;
		}
	}
	return _tdescription;
}

- (void)setTdescription: (NSString *)new
{
	if(_tdescription == new)
		return;
	[_tdescription release];
	_tdescription = [new retain];
}

- (NSString *)title
{
	if(_title == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2name" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.title = [currentChild stringValue];
			break;
		}
	}
	return _title;
}

- (void)setTitle: (NSString *)new
{
	if(_title == new)
		return;
	[_title release];
	_title = [new retain];
}

- (NSObject<ServiceProtocol> *)service
{
	if(_service == nil)
	{
		NSArray *resultNodes = nil;
		NSString *sname = nil;
		NSString *sref = nil;

		resultNodes = [_node nodesForXPath:@"e2servicename" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			sname = [[currentChild stringValue] retain];
			break;
		}

		resultNodes = [_node nodesForXPath:@"e2servicereference" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			sref = [[currentChild stringValue] retain];
			break;
		}

		if(sname && sref)
		{
			_service = [[GenericService alloc] init];
			_service.sname = sname;
			_service.sref = sref;
		}
		[sname release];
		[sref release];
	}
	return _service;
}

- (void)setService: (NSObject<ServiceProtocol> *)new
{
	if(_service == new)
		return;
	[_service release];
	_service = [new retain];
}

- (NSString *)sname
{
	return nil;
}

- (NSString *)sref
{
	return nil;
}

- (NSDate *)end
{
	if(_end == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2timeend" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			_end = [[NSDate dateWithTimeIntervalSince1970: [[currentChild stringValue] doubleValue]] retain];
			break;
		}
	}
	return _end;
}

- (void)setEnd: (NSDate *)new
{
	if(_end == new)
		return;
	[_end release];
	_end = [new retain];
}

- (NSDate *)begin
{
	if(_begin == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2timebegin" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			_begin = [[NSDate dateWithTimeIntervalSince1970: [[currentChild stringValue] doubleValue]] retain];
			break;
		}
	}
	return _begin;
}

- (void)setBegin: (NSDate *)new
{
	if(_begin == new)
		return;
	[_begin release];
	_begin = [new retain];
}

- (NSString *)eit
{
	if(_eit == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2eit" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.eit = [resultElement stringValue];
			break;
		}
	}
	return _eit;
}

- (void)setEit: (NSString *)new
{
	if(_eit == new)
		return;
	[_eit release];
	_eit = [new retain];
}

- (BOOL)disabled
{
	if(!_disabledSet)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2disabled" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			_disabledSet = YES;
			_disabled = [[resultElement stringValue] isEqualToString: @"1"];
			break;
		}
	}
	return _disabled;
}

- (void)setDisabled: (BOOL)new
{
	_disabled = new;
}

- (BOOL)justplay
{
	if(!_justplaySet)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2justplay" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			_justplaySet = YES;
			_justplay = [[resultElement stringValue] isEqualToString: @"1"];
			break;
		}
	}
	return _justplay;
}

- (void)setJustplay: (BOOL)new
{
	_justplay = new;
}

- (NSInteger)repeated
{
	if(!_repeatedSet)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2repeated" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			_repeatedSet = YES;
			_repeated = [[resultElement stringValue] integerValue];
			break;
		}
	}
	return _repeated;
}

- (void)setRepeated: (NSInteger)new
{
	_repeated = new;
}

- (NSInteger)afterevent
{
	if(!_aftereventSet)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2afterevent" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			_aftereventSet = YES;
			_afterevent = [[resultElement stringValue] integerValue];
			break;
		}
	}
	return _afterevent;
}

- (void)setAfterevent: (NSInteger)new
{
	_afterevent = new;
}

- (NSInteger)state
{
	if(!_stateSet)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2state" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			_stateSet = YES;
			_state = [[resultElement stringValue] integerValue];
			break;
		}
	}
	return _state;
}

- (void)setState: (NSInteger)new
{
	_state = new;
}

- (id)init
{
	if(self = [super init])
	{
		_service = nil;
		_isValid = YES;
		_timeString = nil;

		_disabledSet = NO;
		_justplaySet = NO;
		_stateSet = NO;
		_aftereventSet = NO;
		_repeatedSet = NO;
	}
	return self;
}

- (id)initWithNode: (CXMLNode *)node
{
	if(self = [self init])
	{
		_node = [node retain];
	}
	return self;
}

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
{
	if(self = [super init])
	{
		_disabledSet = YES;
		_justplaySet = YES;
		_stateSet = YES;
		_aftereventSet = YES;
		_repeatedSet = YES;

		_begin = [timer.begin copy];
		_end = [timer.end copy];
		_eit = [timer.eit copy];
		_title = [timer.title copy];
		_tdescription = [timer.tdescription copy];
		_disabled = timer.disabled;
		_justplay = timer.justplay;
		_service = [timer.service copy];
		_repeated = timer.repeated;
		_state = timer.state;
		_isValid = timer.valid;
		_afterevent = timer.afterevent;

		// NOTE: we don't copy the node...
		// by accessing the properties we can be sure to have all the values though :P
	}

	return self;
}

- (void)dealloc
{
	[_begin release];
	[_end release];
	[_eit release];
	[_title release];
	[_tdescription release];
	[_service release];
	[_timeString release];
	
	[_node release];

	[super dealloc];
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithTimer: self];

	return newElement;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (NSString *)getStateString
{
	return [NSString stringWithFormat: @"%d", _state];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setEndFromString: (NSString *)newEnd
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setSref: (NSString *)newSref
{
	return;
}

- (void)setSname: (NSString *)newSname
{
	return;
}

@end
