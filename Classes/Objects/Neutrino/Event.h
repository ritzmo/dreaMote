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

@interface NeutrinoEvent : NSObject <EventProtocol>
{
@private
	NSString *timeString;

	CXMLNode *_node;
}

- (id)initWithNode: (CXMLNode *)node;

@end
