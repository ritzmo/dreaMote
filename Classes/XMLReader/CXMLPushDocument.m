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

- (BOOL)success
{
	return _node != NULL;
}

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
		_node->_private = self; // Note. NOT retained (TODO think more about _private usage)
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

@end

#endif
