//
//  CXMLPushDocument.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD

#import "CXMLPushDocument.h"

@implementation CXMLPushDocument

@synthesize success;

- (void)dealloc
{
	if(_ctxt)
		xmlFreeParserCtxt(_ctxt);
	_ctxt = NULL;
	[super dealloc];
}

- (id)initWithError: (NSError **)outError
{
	if (self = [super init])
	{
		if(outError)
		{
			*outError = nil;
			_parseError = outError;
		}
		success = NO;
	}
	else if(outError)
		*outError = [NSError errorWithDomain:@"CXMLErrorUnk" code:1 userInfo:NULL];

	return self;
}

- (void)parseChunk: (NSData *)chunk
{
	if(!_ctxt)
		_ctxt = xmlCreatePushParserCtxt(NULL, NULL, [chunk bytes], [chunk length], NULL);
	else
		xmlParseChunk(_ctxt, [chunk bytes], [chunk length], 0);
}

- (void)abortParsing
{
	// Is this enough?
	if(_ctxt)
		xmlFreeParserCtxt(_ctxt);
	_ctxt = NULL;
}

- (NSError *)doneParsing
{
	NSError *outError = nil;
	if(!_ctxt)
	{
		outError = [NSError errorWithDomain:@"CXMLErrorUnk" code:1 userInfo:NULL];
		if(_parseError)
			*_parseError = outError;
		return outError;
	}

	xmlParseChunk(_ctxt, NULL, 0, 1);

	int res = _ctxt->wellFormed;
	if(res)
	{
		success = YES;
		_node = (xmlNodePtr)_ctxt->myDoc;
		NSAssert(_node->_private == NULL, @"TODO");
		_node->_private = self; // Note. NOT retained (TODO think more about _private usage)
	}
	else
	{
		outError = [NSError errorWithDomain:@"CXMLErrorUnk" code:1 userInfo:NULL];
		if(_parseError)
			*_parseError = outError;
		_node = NULL;
	}

    xmlFreeParserCtxt(_ctxt);
	_ctxt = NULL;
	
	return outError;
}

@end

#endif
