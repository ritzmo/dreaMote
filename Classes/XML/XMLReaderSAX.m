/***

Important:

This is sample code demonstrating API, technology or techniques in development.
Although this sample code has been reviewed for technical accuracy, it is not 
final. Apple is supplying this information to help you plan for the adoption of 
the technologies and programming interfaces described herein. This information 
is subject to change, and software implemented based on this sample code should 
be tested with final operating system software and final documentation. Newer 
versions of this sample code may be provided with future seeds of the API or 
technology. For information about updates to this and other developer 
documentation, view the New & Updated sidebars in subsequent documentation seeds.

***/

/*

File: XMLReaderSAX.m
Abstract: A simple SAX parser. Reports only elements, attributes, and the string contents of an element. Does
not handle, comments, processing instructions, entities, or DTDS.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc.
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/



#import "XMLReaderSAX.h"

#import "XMLUtilities.h"

@interface XMLReaderSAX()

// Function prototypes for SAX callbacks. This sample implements a small subset of SAX callbacks.
// Depending on your application's needs, you might want to implement more callbacks.
static void startDocumentSAX (void * ctx);
static void endDocumentSAX (void * ctx);
static void startElementSAX (void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX (void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX	(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX (void * ctx, const char * msg, ...);
static void fatalErrorEncounteredSAX (void * ctx, const char * msg, ...);

@end

static xmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    startDocumentSAX,           /* startDocument */
    endDocumentSAX,             /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    fatalErrorEncounteredSAX,   /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */
};

static xmlSAXHandler *simpleSAXHandler = &simpleSAXHandlerStruct;

@implementation XMLReaderSAX

@synthesize currentModelObject = _currentModelObject;
@synthesize modelObjectDictionary = _modelObjectDictionary;
@synthesize parsedModelObjects = _parsedModelObjects;
@synthesize currentElementContent = _currentElementContent;
@synthesize childElementSetterSelectorName = _childElementSetterSelectorName;

- (NSMutableArray *)parsedModelObjects
{
    if (!_parsedModelObjects) {
        _parsedModelObjects = [[NSMutableArray alloc] init];
    }
    return _parsedModelObjects;
} 

- (void)releaseModelObjects
{
    if (_parsedModelObjects) {
        [_parsedModelObjects release];
    }
}

- (void)parseXML:(const char *)XMLString parseError:(NSError **)parseError
{
    if (!XMLString) {
        return;
    }

    xmlParserCtxtPtr ctxt = xmlCreateDocParserCtxt((xmlChar*)XMLString);
    
    [[self parsedModelObjects] removeAllObjects]; // Initialize the array that holds the parse results.
    
    int parseResult = xmlSAXUserParseMemory(simpleSAXHandler, self, XMLString, strlen(XMLString));
    
    if (parseResult != 0 && parseError) {
        *parseError = [NSError errorWithDomain:XMLParsingErrorDomainString code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Parsing failed", NSLocalizedFailureReasonErrorKey, nil]]; 
    }
    
    xmlFreeParserCtxt(ctxt);
    xmlCleanupParser();
    xmlMemoryDump();
}

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error
{
    NSError *err = nil;
    NSString *URLContents = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&err];
    
    if (!URLContents) {
        return;
    }
        
    return [self parseXML:[URLContents UTF8String] parseError:error];
}

// Caller is responsible for releasing the returned string.
static NSString *
getQualifiedName (const xmlChar *prefix, const xmlChar *localName)
{
    if (!prefix || !localName) {
        return nil;
    }

    int bufferSize = strlen((const char *)prefix) + strlen((const char *)localName) + 1 + 1; // Add one for the colon and one for the NULL terminator.
    char qualifiedNameBuffer[bufferSize];
    
    // Copy prefix into a buffer so it can be modified.
    strlcpy(qualifiedNameBuffer, (const char *)prefix, sizeof(qualifiedNameBuffer));
        
    const char *colon = ":";
    // Add a colon after the prefix.
    strlcat(qualifiedNameBuffer, colon, sizeof(qualifiedNameBuffer));
    
    // Add the local name after teh colon.
    strlcat(qualifiedNameBuffer, (const char*)localName, sizeof(qualifiedNameBuffer));
    
    return [[NSString alloc] initWithUTF8String:qualifiedNameBuffer];
}

static void 
startDocumentSAX (void * ctx)
{
}

static void 
endDocumentSAX (void * ctx)
{
}

static void
startElementSAX(void *ctx,
                const xmlChar *localname,
                const xmlChar *prefix,
                const xmlChar *URI,
                int nb_namespaces,
                const xmlChar **namespaces,
                int nb_attributes,
                int nb_defaulted,
                const xmlChar **attributes)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    XMLReaderSAX *currentReader = (XMLReaderSAX *)ctx;
    if (currentReader.currentElementContent) {
        [currentReader.currentElementContent release];
        currentReader.currentElementContent = nil;
    } 
    
    NSString *qualifiedName = nil;
    if (prefix) {
        qualifiedName = getQualifiedName(prefix, localname);
    } else {
        qualifiedName = [[NSString alloc] initWithUTF8String:(const char *)localname];
    }
    
    // The parser has encountered an element. Look in the dictionary that the client set before
    // the parse began for a class name to use to instantiate and fill with the data of the current element.
    // Add the new model object to the array of parsed model objects, which the client uses to retrieve
    // the results of the parse.
    NSString *classNameForElement = [[currentReader modelObjectDictionary] valueForKey:qualifiedName];
        
    id currentModelObject = currentReader.currentModelObject;
    
    if (currentModelObject) {
        if (!classNameForElement) {
            // The current model object doesn't match the current element, so the element could be a child of the model object.
            if ([[[currentModelObject class] childElements] valueForKey:qualifiedName]) {
                
                NSString *setterSelectorString = [[[currentModelObject class] setterMethodsAndChildElementNames] valueForKey:qualifiedName];
                
                // Set in an ivar the selector on the current model object to use in endElement to set the collected characters
                // for the child element.
                
                currentReader.childElementSetterSelectorName = setterSelectorString;
            }
        }
    }
    
    [qualifiedName release];
    
    if (classNameForElement && [classNameForElement length]) {
        id newModelObject = [[NSClassFromString(classNameForElement) alloc] init];
        currentReader.currentModelObject = newModelObject;
        [currentReader.parsedModelObjects addObject:newModelObject];
        [newModelObject release];
    }
    
    // The 'attributes' argument is a pointer to an array of attributes.
    // Each attribute has five properties: local name, prefix, URI, value, and end.
    // So the first attribute in the array starts at index 0; the second one starts
    // at index 5.
    
    NSUInteger attributeCounter, maxAttributes = nb_attributes * 5;
    for (attributeCounter = 0; attributeCounter < nb_attributes; attributeCounter++) {
    
        NSString *localNameString = nil;
        NSString *prefixString = nil;
        NSString *URIString = nil;
        NSString *valueString = nil;
        
        BOOL releaseLocalNameString = NO;
        
        // Get the attribute's local name.
        const xmlChar *localName = attributes[attributeCounter];

        // Increment the counter to get the attribute's prefix.
        attributeCounter++;
        const xmlChar *attributePrefix = attributes[attributeCounter];
        
        // Increment the counter to the attribute's URI.
        attributeCounter++;
        const char *URI = (const char *)attributes[attributeCounter];
        if (URI) {
            URIString = [[NSString alloc] initWithUTF8String:URI];
        }
        
        // Increment the counter to get the attribute's value.
        attributeCounter++;
        
        // The beginning of the attribute value starts at index 3 in the array.
        // The end of the attribute value starts at index 4 in the array.
        const char *valueBegin = (const char *)attributes[attributeCounter];
        const char *valueEnd = (const char *)attributes[attributeCounter + 1];
      
        if (valueBegin && valueEnd) {
            // Not sure why it's getting the attribute value is so convoluted.
            valueString = [[NSString alloc] initWithBytes:attributes[attributeCounter] length:(strlen(valueBegin) - strlen(valueEnd)) encoding:NSUTF8StringEncoding];
        }
        
        // Increment the counter to move to the 'end' of the attribute, so the loop is iterator will advance to the next attribute.
        attributeCounter++;
                
        if (currentReader.currentModelObject) {
            NSMutableDictionary *modelObjectAttributes = [currentReader.currentModelObject XMLAttributes];
            if (!modelObjectAttributes) {
                modelObjectAttributes = [[NSMutableDictionary alloc] init];
                [currentReader.currentModelObject setXMLAttributes:modelObjectAttributes];
                [modelObjectAttributes release];
            }
            
            if (attributePrefix) {
                // The attribute has a namespace prefix, so consider the name of the attribute to
                // be the prefix + the local name.
                localNameString = getQualifiedName(attributePrefix, localName);
                releaseLocalNameString = YES;
            } else {
                localNameString = [[NSString alloc] initWithUTF8String:(const char *)localName];
            }
            
            if (valueString) {
                [modelObjectAttributes setObject:valueString forKey:localNameString];
                
            }
            
            if (releaseLocalNameString) {
                [localNameString release];
            }
        }
        
        if (valueString) {
            [valueString release];
        }
    }
    
    [pool release];
}

static void	
endElementSAX (void *ctx,
               const xmlChar *localname,
               const xmlChar *prefix,
               const xmlChar *URI)
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    XMLReaderSAX *currentReader = (XMLReaderSAX *)ctx;
    
    SEL childElementContentSetter = NSSelectorFromString(currentReader.childElementSetterSelectorName);
    if (!childElementContentSetter) {
        return;
    }
	NSMethodSignature *sig = [currentReader.currentModelObject methodSignatureForSelector:childElementContentSetter];
    if (!sig) {
        return;
    }
        
    NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:sig];
    [invoke setSelector:childElementContentSetter]; 
    NSString *content = currentReader.currentElementContent;
    [invoke setArgument:(void *)&content atIndex:2]; // You want to pass the content of the element, which you don't know yet.
    [invoke invokeWithTarget:currentReader.currentModelObject];
    
    NSString *qualifiedElementName = nil;
    if (prefix) {
        qualifiedElementName = getQualifiedName(prefix, localname);
    }
        
    if ([qualifiedElementName isEqualToString:NSStringFromClass([currentReader.currentModelObject class])]) { 
        currentReader.currentModelObject = nil;
    }
    
    if (qualifiedElementName) {
        [qualifiedElementName release];
    }

    currentReader.currentElementContent = nil;
    currentReader.childElementSetterSelectorName = nil;
    
    [pool release];
}

static void	
charactersFoundSAX	(void * ctx, const xmlChar * ch, int len)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    XMLReaderSAX *currentReader = (XMLReaderSAX *)ctx;
    
    CFStringRef str = CFStringCreateWithBytes(kCFAllocatorSystemDefault, ch, len, kCFStringEncodingUTF8, false);
    
    if (!currentReader.currentElementContent) {
        currentReader.currentElementContent = [[NSMutableString alloc] init];
    }
    
    [currentReader.currentElementContent appendString:(NSString *)str];
        
    CFRelease(str);
    
    [pool release];
}

static void 
errorEncounteredSAX (void * ctx, const char * msg, ...)
{
    NSLog(@"errorEncountered: %s", msg);
}

static void 
fatalErrorEncounteredSAX (void * ctx, const char * msg, ...)
{
    NSLog(@"fatalErrorEncountered: %s", msg);
}

@end
