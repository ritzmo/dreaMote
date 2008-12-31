//
//  BaseXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import "BaseXMLReader.h"

@interface BaseXMLReader()
- (void)sendErroneousObject;
@end

@implementation BaseXMLReader

@synthesize target = _target;
@synthesize addObject = _addObject;
@synthesize supportsIncremental;
@synthesize finished;

- (id)init
{
	if(self = [super init])
	{
		finished = NO;
		supportsIncremental = NO;
	}
	return self;
}

- (void)dealloc
{
	[_target release];
	[_parser release];

	[super dealloc];
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	BaseXMLReader *xmlReader = [[BaseXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	[self parseXMLFileAtURL: URL parseError: error parseImmediately: YES];
}

- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error parseImmediately: (BOOL)doParse
{
	finished = NO;
#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	_parser = [[CXMLPushDocument alloc] initWithError: error];

	// bail out if we encountered an error
	if(error && *error)
	{
		if(doParse)
			[self sendErroneousObject];
		return;
	}

	NSURLRequest *request = [NSURLRequest requestWithURL: URL cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 50];
	NSURLConnection *connection = [[NSURLConnection alloc]
									initWithRequest:request
									delegate:self
									startImmediately:NO];

	if(!connection)
	{
		if(doParse)
			[self sendErroneousObject];
		return;
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop]
							forMode: DataDownloaderRunMode];
	[connection start];

	while (!finished) // a BOOL flagged in the delegate methods
	{
		[[NSRunLoop currentRunLoop] runMode: DataDownloaderRunMode
								beforeDate:[NSDate dateWithTimeIntervalSinceNow:15.0]];
	}
	[connection release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if(!_parser.success)
	{
		if(doParse)
			[self sendErroneousObject];
		return;

	}
#else
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	_parser = [[CXMLDocument alloc] initWithContentsOfURL:URL options: 0 error: error];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	finished = YES;

	// bail out if we encountered an error
	if(error && *error)
	{
		if(doParse)
			[self sendErroneousObject];
		return;
	}
#endif

	if(doParse)
		[self parseInitial];
}

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_parser parseChunk: data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	finished = YES;

	[_parser abortParsing];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	finished = YES;

	[_parser doneParsing];
}

#endif //LAME_ASYNCHRONOUS_DOWNLOAD

- (void)sendErroneousObject
{
	// XXX: descending classes should implement this
}

- (void)parseFull
{
	// XXX: descending classes should implement this
}

- (void)parseInitial
{
	// If a descending class implements this it should set supportsIncremental to YES
	[self parseFull];
}

- (id)parseSpecific: (NSString *)identifier
{
	// This function will only be called when supportsIncremental is set to YES
	return nil;
}

@end
