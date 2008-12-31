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

@interface EnigmaTimerXMLReader : BaseXMLReader
{
}

+ (EnigmaTimerXMLReader*)initWithTarget:(id)target action:(SEL)action;

@end
