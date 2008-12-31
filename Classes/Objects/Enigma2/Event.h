//
//  Event.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "EventProtocol.h"

@interface Enigma2Event : NSObject <EventProtocol>
{
@private	
	NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	NSString *_title;
	NSString *_sdescription;
	NSString *_edescription;

	NSString *timeString;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
