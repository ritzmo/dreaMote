//
//  SaxXmlReader.m
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "SaxXmlReader.h"

#import <Delegates/AppDelegate.h>
#import <Connector/RemoteConnectorObject.h>

#import <Constants.h>

#import "NSObject+Queue.h"

@interface SynchronousRequestReader()
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end

@interface SaxXmlReader()
- (void)charactersFound:(const xmlChar *)characters length:(int)length;
- (void)parsingError:(NSString *)msg;
- (void)endDocument;
@end

// formward declare
static xmlSAXHandler libxmlSAXHandlerStruct;

@implementation SaxXmlReader

@synthesize currentString, currentItems;
@synthesize delegate = _delegate;
@synthesize encoding;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_timeout = kTimeout;
		encoding = NSUTF8StringEncoding;
	}
	return self;
}

- (void)dealloc
{
	xmlFreeParserCtxt(_xmlParserContext);
	_xmlParserContext = NULL;
}

- (BOOL)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	NSError *failureReason = nil;
	@autoreleasepool
	{
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL
													  cachePolicy:NSURLRequestReloadIgnoringCacheData
												  timeoutInterval:_timeout];
		NSURLConnection *con = nil;

		if(request)
			con = [[NSURLConnection alloc] initWithRequest:request delegate:self];
#if IS_DEBUG()
		else
			[NSException raise:@"ExcSaxXmlReaderNoRequest" format:@""];
#endif

		if(con)
		{
			[APP_DELEGATE addNetworkOperation];
			_xmlParserContext = xmlCreatePushParserCtxt(&libxmlSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
			xmlCtxtUseOptions(_xmlParserContext, XML_PARSE_NOENT | XML_PARSE_RECOVER);

			_running = YES;
			while(_running)
			{
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
			}
			[con cancel]; // just in case, cancel the connection
			[APP_DELEGATE removeNetworkOperation];

			xmlFreeParserCtxt(_xmlParserContext);
			_xmlParserContext = NULL;

			failureReason = self.error;
		}
		else
		{
#if IS_DEBUG()
			[NSException raise:@"ExcSaxXmlReaderNoConnection" format:@""];
#else
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedString(@"Unknown connection error occured.", @"Data connection failed for unknown reason.")
																 forKey:NSLocalizedDescriptionKey];
			failureReason = [NSError errorWithDomain:@"myDomain"
												code:900
											userInfo:userInfo];
#endif
		}

		if(failureReason)
		{
			if(error)
				*error = failureReason;
			[[self queueOnMainThread] errorLoadingDocument:failureReason];
		}
		else
			[[self queueOnMainThread] finishedParsingDocument];
	} // /@autoreleasepool
	return failureReason == nil;
}

+ (NSData *)sendSynchronousRequest:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error withTimeout:(NSTimeInterval)timeout
{
#if IS_DEBUG()
	[NSException raise:@"ExcWrongClass" format:@"Tried to send synchronous request using %@", [self class]];
#endif
	return nil;
}

- (void)errorLoadingDocument:(NSError *)error
{
	if([_delegate respondsToSelector:@selector(dataSourceDelegate:errorParsingDocument:)])
	{
		[_delegate dataSourceDelegate:self errorParsingDocument:error];
	}
}

- (void)finishedParsingDocument
{
	if([_delegate respondsToSelector:@selector(dataSourceDelegateFinishedParsingDocument:)])
	{
		[_delegate dataSourceDelegateFinishedParsingDocument:self];
	}
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
												 encoding:self.encoding];
		[currentString appendString:value];
	}
}

- (void)parsingError:(NSString *)msg
{
#if IS_DEBUG()
	NSLog(@"[%@] parsingError: %@", [self class], msg);
#endif
	// return on errors starting with PCDATA (assume bad encoding)
	if([msg hasPrefix:@"PCDATA"])
		return;

	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey];
	NSError *error = [NSError errorWithDomain:@"ParsingDomain" code:101 userInfo:userInfo];
	xmlStopParser(_xmlParserContext); // abort parsing (NOTE: we might want to gather all errors first)
	self.error = error;
	_running = NO;
}

- (void)endDocument
{
	_running = NO;
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

#pragma mark -
#pragma mark NSURLConnection delegate methods
#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	xmlParseChunk(_xmlParserContext, (const char *)[data bytes], [data length], 0);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if([response respondsToSelector:@selector(statusCode)])
	{
		NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
		if (statusCode > 399)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Connection to remote host failed with status code %d (%@).", @""), statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]]
																 forKey:NSLocalizedDescriptionKey];
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain
												 code:statusCode
											 userInfo:userInfo];

			// release parser so it does not overwrite our custom error due to a race condition
			xmlFreeParserCtxt(_xmlParserContext);
			_xmlParserContext = NULL;

			[self connection:connection didFailWithError:error];
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	xmlParseChunk(_xmlParserContext, NULL, 0, 1);
	// NOTE: don't set _running, instead let the parser do it because it will be destroyed afterwards
}

@end

#pragma mark -
#pragma mark libxml2 c callbacks
#pragma mark -

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
	[(__bridge SaxXmlReader *)ctx elementFound:localname
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
	[(__bridge SaxXmlReader *)ctx endElement:localname prefix:prefix uri:URI];
}

static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len)
{
	[(__bridge SaxXmlReader *)ctx charactersFound:ch length:len];
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...)
{
	CFStringRef format = CFStringCreateWithBytesNoCopy(NULL, (const UInt8 *)msg, strlen(msg), kCFStringEncodingUTF8, false, kCFAllocatorNull);
	CFStringRef resultString = NULL;
	va_list argList;
	va_start(argList, msg);
	resultString = CFStringCreateWithFormatAndArguments(NULL, NULL, format, argList);
	va_end(argList);

	[(__bridge SaxXmlReader *)ctx parsingError:(__bridge NSString *)resultString];

	CFRelease(format);
	CFRelease(resultString);
}

static void endDocumentSAX(void *ctx)
{
	[(__bridge SaxXmlReader *)ctx endDocument];
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
