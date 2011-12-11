//
//  BaseXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "BaseXMLReader.h"

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	#import "AppDelegate.h"
#endif

#import "SynchronousRequestReader.h"
#import "Constants.h"

/*!
 @brief Private functions of BaseXMLReader.
 */
@interface BaseXMLReader()
/*!
 @brief Parse XML Document.
 */
- (void)parseFull;
@end

@implementation BaseXMLReader

@synthesize encoding, document;
@synthesize delegate = _delegate;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_done = NO;
		_timeout = kTimeout;
		encoding = NSUTF8StringEncoding;
	}
	return self;
}

/* download and parse xml document */
- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	document = nil;
	_done = NO;
	NSError __autoreleasing *localError = nil;
#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	NSError *__unsafe_unretained parserError = localError;
	document = [[CXMLPushDocument alloc] initWithError:&parserError];

	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL
												  cachePolicy:NSURLRequestReloadIgnoringCacheData
											  timeoutInterval:_timeout];
	NSURLConnection *connection = [[NSURLConnection alloc]
									initWithRequest:request
									delegate:document];
	if(connection)
	{
		[APP_DELEGATE addNetworkOperation];
		do
		{
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!document.done);
		[APP_DELEGATE removeNetworkOperation];
		[connection cancel]; // just in case, cancel the connection
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
		document = [[CXMLDocument alloc] initWithData:data encoding:encoding options:0 error:&localError];
#endif
	_done = YES;
	// set error to eventual local error
	if(error)
		*error = localError;

	// bail out if we encountered an error
	if(localError)
	{
		[self errorLoadingDocument:localError];
		document = nil;
	}
	// else parse document and notify delegate
	else
	{
		[self parseFull];
		[self finishedParsingDocument];
	}
	return document;
}

- (void)errorLoadingDocument:(NSError *)error
{
	// delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:);
	NSMethodSignature *sig = [_delegate methodSignatureForSelector:errorParsing];
	if(_delegate && [_delegate respondsToSelector:errorParsing] && sig)
	{
		BaseXMLReader *__unsafe_unretained dataSource = self;
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:_delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&dataSource atIndex:2];
		[invocation setArgument:&error atIndex:3];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)finishedParsingDocument
{
	// delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegateFinishedParsingDocument:);
	NSMethodSignature *sig = [_delegate methodSignatureForSelector:finishedParsing];
	if(_delegate && [_delegate respondsToSelector:finishedParsing] && sig)
	{
		BaseXMLReader *__unsafe_unretained dataSource = self;
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:_delegate];
		[invocation setSelector:finishedParsing];
		[invocation setArgument:&dataSource atIndex:2];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

/* parse complete xml document */
- (void)parseFull
{
	// NOTE: descending classes should implement this
}

@end
