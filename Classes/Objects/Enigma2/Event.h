//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "EventProtocol.h"

@interface Enigma2Event : NSObject <EventProtocol>
{
@private
	NSString *timeString;
	NSDate *_begin;
	NSDate *_end;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
