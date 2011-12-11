//
//  MovieXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MovieXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Movie.h>

#import "NSObject+Queue.h"

static const char *kEnigma2MovieElement = "e2movie";
static const NSUInteger kEnigma2MovieElementLength = 8;
static const char *kEnigma2MovieTitle = "e2title";
static const NSUInteger kEnigma2MovieTitleLength = 8;
static const char *kEnigma2MovieTime = "e2time";
static const NSUInteger kEnigma2MovieTimeLength = 7;
static const char *kEnigma2MovieLength = "e2length";
static const NSUInteger kEnigma2MovieLengthLength = 9;
static const char *kEnigma2MovieFilename = "e2filename";
static const NSUInteger kEnigma2MovieFilenameLength = 11;
static const char *kEnigma2MovieFilesize = "e2filesize";
static const NSUInteger kEnigma2MovieFilesizeLength = 11;

@interface Enigma2MovieXMLReader()
@property (nonatomic, strong) NSObject<MovieProtocol> *currentMovie;
@end

@implementation Enigma2MovieXMLReader

@synthesize currentMovie;

/* initialize */
- (id)initWithDelegate:(NSObject<MovieSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		_timeout = kTimeout * 3; // a lot higher timeout to allow to spin up hdd
		if([delegate respondsToSelector:@selector(addMovies:)])
			self.currentItems = [NSMutableArray arrayWithCapacity:kBatchDispatchItemsCount];
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<MovieProtocol> *fakeObject = [[GenericMovie alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[(NSObject<MovieSourceDelegate> *)_delegate addMovie:fakeObject];
	[super errorLoadingDocument:error];
}

- (void)finishedParsingDocument
{
	if(self.currentItems.count)
	{
		[(NSObject<MovieSourceDelegate> *)_delegate addMovies:self.currentItems];
		[self.currentItems removeAllObjects];
	}
	[super finishedParsingDocument];
}

/*
Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2movielist>
 <e2movie>
 <e2servicereference>1:0:0:0:0:0:0:0:0:0:/hdd/movie/20080723 0916 - ProSieben - Scrubs - Die Anfänger.ts</e2servicereference>
 <e2title>Scrubs - Die Anfänger</e2title>
 <e2description>Scrubs - Die Anfänger</e2description>
 <e2descriptionextended>Ted stellt sich gegen Kelso, als er sich für höhere Löhne für die Schwestern einsetzt. Todd hat seine Berufung in der plastischen Chirurgie gefunden. Als Turk sich dagegen einsetzt, dass ein sechzehnjähriges Mädchen eine Brust-OP bekommt, sieht Todd sich gezwungen, seinen Freund umzustimmen, denn dessen Job hängt davon ab. Jordan mischt sich in Keith und Elliotts Beziehung ein, was sich als nicht so gute Idee herausstellt.</e2descriptionextended>
 <e2servicename>ProSieben</e2servicename>
 <e2time>1216797360</e2time>
 <e2length>disabled</e2length>
 <e2tags></e2tags>
 <e2filename>/hdd/movie/20080723 0916 - ProSieben - Scrubs - Die Anfänger.ts</e2filename>
 <e2filesize>1649208192</e2filesize>
 </e2movie>
 </e2movielist>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2MovieElement, kEnigma2MovieElementLength))
	{
		self.currentMovie = [[GenericMovie alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength)
			||	!strncmp((const char *)localname, kEnigma2MovieTitle, kEnigma2MovieTitleLength)
			||  !strncmp((const char *)localname, kEnigma2DescriptionExtended, kEnigma2DescriptionExtendedLength)
			||	!strncmp((const char *)localname, kEnigma2Description, kEnigma2DescriptionLength)
			||	!strncmp((const char *)localname, kEnigma2MovieTime, kEnigma2MovieTimeLength)
			||	!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength)
			||	!strncmp((const char *)localname, kEnigma2MovieLength, kEnigma2MovieLengthLength)
			||	!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength)
			||	!strncmp((const char *)localname, kEnigma2MovieFilename, kEnigma2MovieFilenameLength)
			||	!strncmp((const char *)localname, kEnigma2MovieFilesize, kEnigma2MovieFilesizeLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2MovieElement, kEnigma2MovieElementLength))
	{
		if(self.currentItems)
		{
			[self.currentItems addObject:currentMovie];
			if(self.currentItems.count >= kBatchDispatchItemsCount)
			{
				NSArray *dispatchArray = [self.currentItems copy];
				[self.currentItems removeAllObjects];
				[[_delegate queueOnMainThread] addMovies:dispatchArray];
			}
		}
		else
			[[_delegate queueOnMainThread] addMovie:currentMovie];
	}
	else if(!strncmp((const char *)localname, kEnigma2DescriptionExtended, kEnigma2DescriptionExtendedLength))
	{
		currentMovie.edescription = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Description, kEnigma2DescriptionLength))
	{
		currentMovie.sdescription = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2MovieTitle, kEnigma2MovieTitleLength))
	{
		currentMovie.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2MovieLength, kEnigma2MovieLengthLength))
	{
		if([currentString isEqualToString: @"disabled"] || [currentString isEqualToString: @"?:??"])
		{
			currentMovie.length = [NSNumber numberWithInteger: -1];
		}
		else
		{
			const NSRange range = [currentString rangeOfString: @":"];
			const NSInteger minutes = [[currentString substringToIndex: range.location] integerValue];
			const NSInteger seconds = [[currentString substringFromIndex: range.location + 1] integerValue];
			currentMovie.length = [NSNumber numberWithInteger: (minutes * 60) + seconds];
		}
	}
	else if(!strncmp((const char *)localname, kEnigma2MovieTime, kEnigma2MovieTimeLength))
	{
		[currentMovie setTimeFromString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength))
	{
		[currentMovie setTagsFromString: currentString];
	}
	else if(!strncmp((const char *)localname, kEnigma2MovieFilename, kEnigma2MovieFilenameLength))
	{
		currentMovie.filename = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2MovieFilesize, kEnigma2MovieFilesizeLength))
	{
		currentMovie.size = [NSNumber numberWithLongLong: [currentString longLongValue]];;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		currentMovie.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
		currentMovie.sname = currentString;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
