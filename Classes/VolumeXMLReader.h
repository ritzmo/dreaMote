// Header

#import <Foundation/Foundation.h>

#import "Volume.h"
#import "BaseXMLReader.h"

@interface VolumeXMLReader : BaseXMLReader
{
@private
	Volume *_currentVolumeObject;
}

+ (VolumeXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Volume *currentVolumeObject;

@end
