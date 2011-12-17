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

static const char *kEnigmaService = "service";
static NSUInteger kEnigmaServiceLength = 8;

@interface EnigmaMovieXMLReader()
@property (nonatomic, strong) GenericMovie *currentMovie;
@end

@implementation EnigmaMovieXMLReader

@synthesize currentMovie;

/* initialize */
- (id)initWithDelegate:(NSObject<MovieSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		count = 0;
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
 <movies>
  <service><reference>1:0:1:6dcf:44d:1:c00000:93d2d1:0:0:/hdd/movie/WDR Köln - Rockpalast - Haldern Pop 2006 - 26_08_06.ts</reference><name>Rockpalast - Haldern Pop 2006</name><orbital_position>192</orbital_position></service>
 </movies>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigmaService, kEnigmaServiceLength))
	{
		currentMovie = [[GenericMovie alloc] init];
		currentMovie.time = [NSDate dateWithTimeIntervalSince1970:count++];
		currentMovie.timeString = @"";
	}
	else if(	!strncmp((const char *)localname, kEnigmaReference, kEnigmaReferenceLength)
			||	!strncmp((const char *)localname, kEnigmaName, kEnigmaNameLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigmaService, kEnigmaServiceLength))
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
		{
			[[_delegate queueOnMainThread] addMovie:currentMovie];
		}
	}
	else if(!strncmp((const char *)localname, kEnigmaReference, kEnigmaReferenceLength))
	{
		currentMovie.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaName, kEnigmaNameLength))
	{
		// TODO: check if replace is still needed with new parser
		currentMovie.title = [currentString stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
	}
	currentString = nil;
}

@end
