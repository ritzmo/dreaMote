//
//  CXMLPushDocument.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD

#import "CXMLPushDocument.h"

#import "RemoteConnectorObject.h"

@interface CXMLPushDocument()
/*!
 @brief Finish parsing.

 @note Will be called by creator when no more data units should be parsed.
 */
- (void)doneParsing;
@end

@implementation CXMLPushDocument

@synthesize done = _done;

/* dealloc */
- (void)dealloc
{
	if(_ctxt)
		xmlFreeParserCtxt(_ctxt);
	_ctxt = NULL;
}

/* initialize */
- (id)initWithError: (NSError * __unsafe_unretained *)outError
{
	if((self = [super init]))
	{
		if(outError)
		{
			*outError = nil;
			_parseError = outError;
		}
		_done = NO;
	}
	else if(outError)
		*outError = [NSError errorWithDomain:@"CXMLErrorUnk" code:1 userInfo:NULL];

	return self;
}

/* finish parsing */
- (void)doneParsing
{
	if(!_ctxt)
	{
		if(_parseError)
			*_parseError = [NSError errorWithDomain:@"CXMLErrorUnk" code:1 userInfo:NULL];
		return;
	}

	xmlParseChunk(_ctxt, NULL, 0, 1);

	int res = _ctxt->wellFormed;
	if(res)
	{
		_node = (xmlNodePtr)_ctxt->myDoc;
		NSAssert(_node->_private == NULL, @"TODO");
		_node->_private = (__bridge void *)self; // Note. NOT retained (TODO think more about _private usage)
	}
	else
	{
		if(_parseError)
			*_parseError = [NSError errorWithDomain:@"CXMLErrorUnk" code:1 userInfo:NULL];
		_node = NULL;
	}

    xmlFreeParserCtxt(_ctxt);
	_ctxt = NULL;
}

#pragma mark NSURLConnection delegate methods

/* should authenticate? */
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return YES;
}

/* do authenticate */
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// TODO: ask user to accept certificate
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
			 forAuthenticationChallenge:challenge];
		return;
	}
	else if([challenge previousFailureCount] < 2) // ssl might have failed already
	{
		NSURLCredential *creds = [RemoteConnectorObject getCredential];
		if(creds)
		{
			[challenge.sender useCredential:creds forAuthenticationChallenge:challenge];
			return;
		}
	}

	// NOTE: continue just swallows all errors while cancel gives a weird message,
	// but a weird message is better than no response
	//[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
	[challenge.sender cancelAuthenticationChallenge:challenge];
}

/* received data */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(!_ctxt)
		_ctxt = xmlCreatePushParserCtxt(NULL, NULL, [data bytes], [data length], NULL);
	else
		xmlParseChunk(_ctxt, [data bytes], [data length], 0);
}

/* connection failed */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	*_parseError = error;
	_done = YES;

	// cleanup
	if(_ctxt)
		xmlFreeParserCtxt(_ctxt);
	_ctxt = NULL;
}

/* _done */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self doneParsing];

	_done = YES;
}

@end

#endif
