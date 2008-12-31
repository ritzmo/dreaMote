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
- (void)parseAllEnigma2;
- (void)parseAllEnigma1;
- (void)parseAllNeutrino;
@end

@implementation BaseXMLReader

@synthesize target = _target;
@synthesize addObject = _addObject;

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
- (id)init
{
	if(self = [super init])
	{
		finished = NO;
	}
	return self;
}
#endif

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

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error connectorType:(enum availableConnectors)connector;
{
#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	_parser = [[CXMLPushDocument alloc] initWithError: error];

	// bail out if we encountered an error
	if(error && *error)
	{
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
								beforeDate:[NSDate dateWithTimeIntervalSinceNow:30.0]];
		[NSThread sleepForTimeInterval: 1.0];
	}
	[connection release];

	finished = NO;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(!_parser.success)
	{
		[self sendErroneousObject];
		return;

	}
#else
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	_parser = [[CXMLDocument alloc] initWithContentsOfURL:URL options: 0 error: error];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// bail out if we encountered an error
	if(error && *error)
	{
		[self sendErroneousObject];
		return;
	}
#endif
	
	switch(connector)
	{
		case kEnigma2Connector:
			[self parseAllEnigma2];
			return;
		case kEnigma1Connector:
			[self parseAllEnigma1];
			return;
		case kNeutrinoConnector:
			[self parseAllNeutrino];
			return;
		default:
			[self sendErroneousObject];
			return;
	}
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

- (void)parseAllEnigma2
{
	// XXX: descending classes should implement this
}

- (void)parseAllEnigma1
{
	// XXX: descending classes should implement this
}

- (void)parseAllNeutrino
{
	// XXX: descending classes should implement this
}

@end
