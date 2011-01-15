//
//  SaxXmlReader.m
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SaxXmlReader.h"

@interface SaxXmlReader()
- (void)charactersFound:(const xmlChar *)characters length:(int)length;
- (void)parsingError:(const char *)msg, ...;
- (void)endDocument;
@end

// formward declare
static xmlSAXHandler libxmlSAXHandlerStruct;

@implementation SaxXmlReader

@synthesize currentString;

- (void)dealloc
{
	[currentString release];
	xmlFreeParserCtxt(_xmlParserContext);
	_xmlParserContext = NULL;

	[super dealloc];
}

- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	NSURLRequest *request = [NSURLRequest requestWithURL: URL
											 cachePolicy: NSURLRequestReloadIgnoringCacheData
										 timeoutInterval: _timeout];
	NSURLConnection *con = [[NSURLConnection alloc]
							initWithRequest:request
							delegate:self];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	_xmlParserContext = xmlCreatePushParserCtxt(&libxmlSAXHandlerStruct, self, NULL, 0, NULL);
	do
	{
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	} while (!_done);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[self sendTerminatingObject];

	[con release];
	return nil;
}

#pragma mark -
#pragma mark libxml2 objc callbacks
#pragma mark -

- (void)charactersFound:(const xmlChar *)characters length:(int)length
{
	if(currentString)
	{
		NSString *value = [[NSString alloc] initWithBytes:(const void *)characters
												   length:length
												 encoding:NSUTF8StringEncoding];
		[currentString appendString:value];
		[value release];
	}
}

- (void)parsingError:(const char *)msg, ...
{
	// TODO: add proper error handling
#if 0
	NSString *format = [[NSString alloc] initWithBytes:msg
												length:strlen(msg)
											  encoding:NSUTF8StringEncoding];
	CFStringRef resultString = NULL;
	va_list argList;
	va_start(argList, msg);
	resultString = CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)format, argList);
	va_end(argList);

	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:(NSString*)resultString forKey:@"error_message"];
	NSError *error = [NSError errorWithDomain:@"ParsingDomain" code:101 userInfo:userInfo];
#endif

	[self sendErroneousObject];
	_done = YES;

#if 0
	[(NSString*)resultString release];
	[format release];
#endif
}

- (void)endDocument
{
	_done = YES;
}

#pragma mark dummy methods

- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	// dummy
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	// dummy
}

- (void)sendErroneousObject
{
	// dummy
}

- (void)sendTerminatingObject
{
	// dummy
}

#pragma mark -
#pragma mark NSURLConnection delegate methods
#pragma mark -

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self sendErroneousObject];
	_done = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	xmlParseChunk(_xmlParserContext, (const char *)[data bytes], [data length], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	xmlParseChunk(_xmlParserContext, NULL, 0, 1);
	_done = YES;
}

@end

#pragma mark -
#pragma mark libxml2 c callbacks
#pragma mark -

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
	[(SaxXmlReader *)ctx elementFound:localname
										prefix:prefix
										   uri:URI
								namespaceCount:nb_namespaces
									namespaces:namespaces
								attributeCount:nb_attributes
						 defaultAttributeCount:nb_defaulted
									attributes:(xmlSAX2Attributes*)attributes];
}

static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI)
{
	[(SaxXmlReader *)ctx endElement:localname prefix:prefix uri:URI];
}

static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len)
{
	[(SaxXmlReader *)ctx charactersFound:ch length:len];
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...)
{
	va_list argList;
	va_start(argList, msg);
	[(SaxXmlReader *)ctx parsingError:msg, argList];
}

static void endDocumentSAX(void *ctx)
{
	[(SaxXmlReader *)ctx endDocument];
}

static xmlSAXHandler libxmlSAXHandlerStruct =
{
	NULL,						/* internalSubset */
	NULL,						/* isStandalone */
	NULL,						/* hasInternalSubset */
	NULL,						/* hasExternalSubset */
	NULL,						/* resolveEntity */
	NULL,						/* getEntity */
	NULL,						/* entityDecl */
	NULL,						/* notationDecl */
	NULL,						/* attributeDecl */
	NULL,						/* elementDecl */
	NULL,						/* unparsedEntityDecl */
	NULL,						/* setDocumentLocator */
	NULL,						/* startDocument */
	endDocumentSAX,				/* endDocument */
	NULL,						/* startElement*/
	NULL,						/* endElement */
	NULL,						/* reference */
	charactersFoundSAX,			/* characters */
	NULL,						/* ignorableWhitespace */
	NULL,						/* processingInstruction */
	NULL,						/* comment */
	NULL,						/* warning */
	errorEncounteredSAX,		/* error */
	NULL,						/* fatalError //: unused error() get all the errors */
	NULL,						/* getParameterEntity */
	NULL,						/* cdataBlock */
	NULL,						/* externalSubset */
	XML_SAX2_MAGIC,				/* initialized */
	NULL,						/* private */
	startElementSAX,			/* startElementNs */
	endElementSAX,				/* endElementNs */
	NULL,						/* serror */
};
