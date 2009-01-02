//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "TimerProtocol.h"
#import "ServiceProtocol.h"

@interface Enigma2Timer : NSObject <TimerProtocol>
{
@private
	NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	BOOL _disabled; 
	NSString *_title;
	NSString *_tdescription;
	NSInteger _repeated;
	BOOL _justplay;
	NSObject<ServiceProtocol> *_service;
	NSInteger _state;
	NSInteger _afterevent;
	BOOL _isValid;
	NSString *timeString;

	// Unfortunately we need some helpers...
	BOOL _disabledSet;
	BOOL _justplaySet;
	BOOL _stateSet;
	BOOL _aftereventSet;
	BOOL _repeatedSet;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
