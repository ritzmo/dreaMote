//
//  TimerXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"

@class Timer;

@interface TimerXMLReader : BaseXMLReader
{
@private
	Timer *_currentTimerObject;
}

+ (TimerXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) Timer *currentTimerObject;

@end
