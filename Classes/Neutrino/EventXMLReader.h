//
//  EventXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 16.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef ENABLE_NEUTRINO_CONNECTOR

#import <Foundation/Foundation.h>

#import "Event.h"
#import "BaseXMLReader.h"

@interface NeutrinoEventXMLReader : BaseXMLReader
{
@private
	Event *_currentEventObject;
}

+ (NeutrinoEventXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Event *currentEventObject;

@end

#endif