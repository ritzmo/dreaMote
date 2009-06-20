//
//  BaseXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import "BaseXMLReader.h"

@interface BaseXMLReader()
- (void)sendErroneousObject;
- (void)parseFull;
@end

@implementation BaseXMLReader

@synthesize finished;

/* initialize */
- (id)initWithTarget:(id)target action:(SEL)action
{
	if(self = [super init])
	{
		finished = NO;
		_target = [target retain];
		_addObject = action;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_target release];
	[_parser release];

	[super dealloc];
}

/* download and parse xml document */
- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	finished = NO;
	NSError *localError = nil;
	if(error)
		*error = nil;

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	_parser = [[CXMLPushDocument alloc] initWithError: &localError];

	// bail out if we encountered an error
	if(localError)
	{
		if(error)
			*error = localError
		[self sendErroneousObject];
		return nil;
	}

	NSURLRequest *request = [NSURLRequest requestWithURL: URL cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 50];
	NSURLConnection *connection = [[NSURLConnection alloc]
									initWithRequest:request
									delegate:self
									startImmediately:NO];

	if(!connection)
	{
		[self sendErroneousObject];
		return nil;
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
		[self sendErroneousObject];
		return nil;

	}
#else //!LAME_ASYNCHRONOUS_DOWNLOAD
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: URL
											cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
											returningResponse: &response error: nil];

	_parser = [[CXMLDocument alloc] initWithData: data options: 0 error: &localError];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	finished = YES;

	// bail out if we encountered an error
	if(localError)
	{
		if(error)
			*error = localError;
		[self sendErroneousObject];
		return nil;
	}
#endif

	[self parseFull];
	return _parser;
}

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
/* received data */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_parser parseChunk: data];
}

/* connection failed */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	finished = YES;

	[_parser abortParsing];
}

/* finished */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	finished = YES;

	[_parser doneParsing];
}

#endif //LAME_ASYNCHRONOUS_DOWNLOAD

/* send fake object back to callback */
- (void)sendErroneousObject
{
	// XXX: descending classes should implement this
}

/* parse complete xml document */
- (void)parseFull
{
	// XXX: descending classes should implement this
}

@end
