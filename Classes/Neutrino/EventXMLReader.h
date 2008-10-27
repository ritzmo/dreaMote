//
//  EventXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 16.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"

@class Event;

@interface NeutrinoEventXMLReader : BaseXMLReader
{
@private
	Event *_currentEventObject;
}

+ (NeutrinoEventXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) Event *currentEventObject;

@end
