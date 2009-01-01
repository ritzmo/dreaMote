//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "EventProtocol.h"

@interface EnigmaEvent : NSObject <EventProtocol>
{
@private
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
