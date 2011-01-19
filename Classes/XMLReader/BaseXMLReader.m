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

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_done = NO;
		_timeout = kDefaultTimeout;
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
	_done = NO;
	NSError *localError = nil;
	if(error)
		*error = nil;

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	_parser = [[CXMLPushDocument alloc] initWithError: &localError];

	// bail out if we encountered an error
	if(localError)
	{
		if(error)
			*error = localError;
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

	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL
												  cachePolicy:NSURLRequestReloadIgnoringCacheData
											  timeoutInterval:_timeout];
	NSURLConnection *connection = [[NSURLConnection alloc]
									initWithRequest:request
									delegate:self];
	[request release];

	if(!connection)
	{
		[self sendErroneousObject];
		return nil;
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	do
	{
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	} while (!_done);
	[connection release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if(!_parser.success)
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
#else //!LAME_ASYNCHRONOUS_DOWNLOAD
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:URL
												 returningResponse:nil
															 error:&localError
													   withTimeout:_timeout];
	if(localError == nil)
		_parser = [[CXMLDocument alloc] initWithData: data options: 0 error: &localError];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	_done = YES;

	// bail out if we encountered an error
	if(localError)
	{
		if(error)
			*error = localError;
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
#endif

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

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD

/* should authenticate? */
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

/* do authenticate */
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// TODO: ask user to accept certificate
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
			 forAuthenticationChallenge:challenge];
	}
	else
	{
		// NOTE: continue just swallows all errors while cancel gives a weird message,
		// but a weird message is better than no response
		//[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
		[challenge.sender cancelAuthenticationChallenge:challenge];
	}
}

/* received data */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_parser parseChunk: data];
}

/* connection failed */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// delegate wants to be informated about errors
	if(_delegate && [_delegate respondsToSelector:@selector(dataSourceDelegate:errorParsingDocument:error:)])
		[_delegate dataSourceDelegate:self errorParsingDocument:nil error:error];

	_done = YES;

	[_parser abortParsing];
}

/* _done */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	_done = YES;

	[_parser doneParsing];
}

#endif //LAME_ASYNCHRONOUS_DOWNLOAD

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
