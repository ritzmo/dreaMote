//
//  EventXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"

@class Event;

@interface EnigmaEventXMLReader : BaseXMLReader
{
@private
	Event *_currentEventObject;
}

+ (EnigmaEventXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) Event *currentEventObject;

@end
