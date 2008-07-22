// Header

#import <Foundation/Foundation.h>

#import "Event.h"
#import "BaseXMLReader.h"

@interface EventXMLReader : BaseXMLReader
{
@private
	Event *_currentEventObject;
}

+ (EventXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Event *currentEventObject;

@end
