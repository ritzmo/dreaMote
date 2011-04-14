//
//  BaseXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "BaseXMLReader.h"

#import "SynchronousRequestReader.h"
#import "Constants.h"

/*!
 @brief Private functions of BaseXMLReader.
 */
@interface BaseXMLReader()
/*!
 @brief Instruct XMLReader to send fake object to callback.
 */
- (void)sendErroneousObject;

/*!
 @brief Parse XML Document.
 */
- (void)parseFull;
@end

@implementation BaseXMLReader

@synthesize encoding = _encoding;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_done = NO;
		_timeout = kTimeout;
		_encoding = NSUTF8StringEncoding;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_delegate release];
	[_parser release];

	[super dealloc];
}

/* download and parse xml document */
- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	[_parser release];
	_parser = nil;
	_done = NO;
	NSError *localError = nil;
#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	_parser = [[CXMLPushDocument alloc] initWithError: &localError];

	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL
												  cachePolicy:NSURLRequestReloadIgnoringCacheData
											  timeoutInterval:_timeout];
	NSURLConnection *connection = [[NSURLConnection alloc]
									initWithRequest:request
									delegate:_parser];
	[request release];
	if(connection)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		do
		{
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!_parser.done);
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		[connection release];
	}
	else
	{
		localError = [NSError errorWithDomain:@"myDomain"
										 code:101
									 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Connection could not be established.", @"") forKey:NSLocalizedDescriptionKey]];
	}
#else //!LAME_ASYNCHRONOUS_DOWNLOAD
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:URL
												 returningResponse:nil
															 error:&localError
													   withTimeout:_timeout];
	if(localError == nil)
		_parser = [[CXMLDocument alloc] initWithData:data encoding:_encoding options:0 error:&localError];
#endif
	_done = YES;
	// set error to eventual local error
	if(error)
		*error = localError;

	// bail out if we encountered an error
	if(localError)
	{
		[self sendErroneousObject];

		// delegate wants to be informated about errors
		SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:error:);
		NSMethodSignature *sig = [_delegate methodSignatureForSelector:errorParsing];
		if(_delegate && [_delegate respondsToSelector:errorParsing] && sig)
		{
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
			[invocation retainArguments];
			[invocation setTarget:_delegate];
			[invocation setSelector:errorParsing];
			[invocation setArgument:&self atIndex:2];
			[invocation setArgument:&_parser atIndex:3];
			[invocation setArgument:&localError atIndex:4];
			[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
									  waitUntilDone:NO];
		}
		return nil;
	}

	[self parseFull];

	// delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegate:finishedParsingDocument:);
	NSMethodSignature *sig = [_delegate methodSignatureForSelector:finishedParsing];
	if(_delegate && [_delegate respondsToSelector:finishedParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:_delegate];
		[invocation setSelector:finishedParsing];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&_parser atIndex:3];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
	return _parser;
}

/* send fake object back to callback */
- (void)sendErroneousObject
{
	// NOTE: descending classes should implement this
}

/* parse complete xml document */
- (void)parseFull
{
	// NOTE: descending classes should implement this
}

@end
