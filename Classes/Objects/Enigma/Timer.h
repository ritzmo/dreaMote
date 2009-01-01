//
//  Timer.h
//  Untitled
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "TimerProtocol.h"

@interface EnigmaTimer : NSObject <TimerProtocol>
{
@private
	NSDate *_begin;
	NSDate *_end;
	NSString *_title;
	BOOL _justplay;
	Service *_service;
	NSString *_sref;
	NSString *_sname;
	NSInteger _state;
	NSInteger _afterevent;
	double _duration;
	BOOL _isValid;
	NSString *timeString;

	// Unfortunately we need a helpers...
	BOOL _typedataSet;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
