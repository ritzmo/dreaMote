// Header

#import <Foundation/Foundation.h>

#import "Timer.h"
#import "BaseXMLReader.h"

@interface TimerXMLReader : BaseXMLReader
{
@private
	Timer *_currentTimerObject;
}

+ (TimerXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Timer *currentTimerObject;

@end
