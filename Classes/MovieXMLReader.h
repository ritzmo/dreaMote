// Header

#import <Foundation/Foundation.h>

#import "Movie.h"
#import "BaseXMLReader.h"

@interface MovieXMLReader : BaseXMLReader
{
@private
	Movie *_currentMovieObject;
}

+ (MovieXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Movie *currentMovieObject;

@end
