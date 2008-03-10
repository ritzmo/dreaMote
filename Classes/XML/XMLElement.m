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

File: XMLElement.m
Abstract: An element in an XML document.

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



#import "XMLElement.h"

#import <libxml/globals.h>
#import <libxml/xmlerror.h>
#import <libxml/parserInternals.h>
#import <libxml/xmlmemory.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

#import "XMLUtilities.h"

static xmlXPathContextPtr _XPathContext;

@interface XMLElement()
- (NSArray *)_nodesForXPath:(NSString *)XPath error:(NSError **)outError;
@end

@implementation XMLElement

@synthesize name;
@synthesize namespacePrefix;
@synthesize children;
@synthesize childCount;
@synthesize firstChild;
@synthesize lastChild;
@synthesize qualifiedName;
@synthesize attributes;
@synthesize attributesString;

static NSArray * childElementsOf(xmlNodePtr a_node, XMLElement *contextElement);
static NSDictionary *getElementAttributes(xmlNode *node);

- (XMLElement *)initWithXMLNode:(xmlNode *)node
{
    self = [super init];
    
    // Everything about an element is computed on demand, including its name,
    // children, and attributes. That saves precious memory. By storing references
    // to the original libxml document and node, we can determine everything else
    // about the node.
    
    self.libXMLNode = node;
    self.libXMLDocument = node->doc;
    
    return self;
}

+ (XMLElement *)elementWithXMLNode:(xmlNode *)node
{
    if (node->type != XML_ELEMENT_NODE) {
        return nil;
    }

    XMLElement *element = [[[self class] alloc] initWithXMLNode:node];
    return [element autorelease];
}

// Creates and returns an XMLElement with 'name'.
+ (XMLElement *)elementWithName:(NSString *)name
{
    NSAssert(name != nil, @"-[XMLElement elementWithName:] argument is nil.");

    xmlNode *newElement = xmlNewNode(NULL, [name xmlChar]);

    XMLElement *element = [[[self class] alloc] initWithXMLNode:newElement];
    return [element autorelease];
}

- (NSString *)description
{
    return [self XMLString];
}

#pragma mark -
#pragma mark    Element Info
#pragma mark -

- (NSString *)XMLString
{    
    NSMutableString *descriptionString = [NSMutableString string];
    if (self.namespacePrefix) {
        [descriptionString appendFormat:@"<%@", [self qualifiedName]];
    } else {
        [descriptionString appendFormat:@"<%@", self.name];
    }
    if (self.attributes && [[self.attributes allKeys] count]) {
        [descriptionString appendFormat:@" %@", [self attributesString]];
    }
    
    [descriptionString appendString:@">"];
    
    for (XMLElement *child in self.children) {
        [descriptionString appendString:[child XMLString]];
    }
    
    if (self.namespacePrefix) {
        [descriptionString appendFormat:@"</%@>", [self qualifiedName]];
    } else {
        [descriptionString appendFormat:@"</%@>", self.name];
    }
    
    return descriptionString;
}

- (NSUInteger)childCount
{
    return [self.children count];
}

- (NSString *)qualifiedName
{
    return [NSString stringWithFormat:@"%@:%@", self.namespacePrefix, self.name];
}

- (NSString *)name
{
    return [XMLUtilities stringWithXMLChar:self.libXMLNode->name];
}

- (NSString *)namespacePrefix
{
    if (self.libXMLNode->ns) {
        return [XMLUtilities stringWithXMLChar:self.libXMLNode->ns->prefix];
    }
    return nil;
}

- (XMLNodeKind)kind
{
    return XMLNodeElementKind;
}

#pragma mark -
#pragma mark    Subtree Access
#pragma mark -

- (NSArray *)children
{
    return childElementsOf(self.libXMLNode, self);
}

- (NSArray *)descendants
{
    NSMutableArray *descendants = [NSMutableArray array];
    NSArray *children = [self children];
    
    for (XMLNode *nextChild in children) {
    
        [descendants addObject:nextChild];
        if (nextChild.isElementNode) {
            [descendants addObjectsFromArray:[(XMLElement *)nextChild descendants]];
        }
    }

    return descendants;
}

#pragma mark -
#pragma mark    Navigation and Queries
#pragma mark -

- (XMLNode *)nextNode
{
    // Given this XML: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A Title.</title><chapter></section><section><para/></section></chapter></document>";
    // If the title element is the context node, nextNode should return its child, which is the text node 'A Title.'
    XMLNode *firstChild = [self firstChild];
    if (firstChild) {
        return firstChild;
    }
    return [self nextSibling];
}

- (XMLNode *)firstChild
{
    if (self.children && [self.children count]) {
        return [self.children objectAtIndex:0];
    }
    return nil;
}

- (XMLNode *)lastChild
{
    return [XMLNode nodeWithXMLNode:xmlGetLastChild(self.libXMLNode)];
}

- (XMLNode *)childAtIndex:(NSUInteger)index
{
    return [self.children objectAtIndex:index];
}

- (XMLElement *)firstChildNamed:(NSString *)matchName
{
    NSArray *allChildrenNamed = [self childrenNamed:matchName];
    if (allChildrenNamed && [allChildrenNamed count]) {
        return [allChildrenNamed objectAtIndex:0];
    }
    return nil;
}

- (XMLElement *)firstDescendantNamed:(NSString *)matchName
{
    NSArray *allDescendantsNamed = [self descendantsNamed:matchName];
    if (allDescendantsNamed && [allDescendantsNamed count]) {
        return [allDescendantsNamed objectAtIndex:0];
    }
    return nil;
}

- (NSArray *)childrenNamed:(NSString *)matchName
{
    NSString *XPathForQuery = [NSString stringWithFormat:@"%@", matchName];
    return [self elementsForXPath:XPathForQuery prepareNamespaces:[NSArray arrayWithObject:matchName] error:nil];
}

- (NSArray *)descendantsNamed:(NSString *)matchName
{
    NSString *XPathForQuery = [NSString stringWithFormat:@"//%@", matchName];
    return [self elementsForXPath:XPathForQuery prepareNamespaces:[NSArray arrayWithObject:matchName] error:nil];
}

- (NSArray *)elementsWithAttributeNamed:(NSString *)attributeName
{
    NSString *XPathForQuery = [NSString stringWithFormat:@"//*[@%@]", attributeName];
    return [self elementsForXPath:XPathForQuery prepareNamespaces:nil error:nil];
}

- (NSArray *)elementsWithAttributeNamed:(NSString *)attributeName attributeValue:(NSString *)attributeValue
{
    NSString *XPathForQuery = [NSString stringWithFormat:@"//*[@%@='%@']", attributeName, attributeValue];
    return [self elementsForXPath:XPathForQuery prepareNamespaces:nil error:nil];
}

- (NSArray *)elementsForXPath:(NSString *)XPath error:(NSError **)outError
{
	return [self elementsForXPath:XPath prepareNamespaces:nil error:nil];
}

- (NSArray *)elementsForXPath:(NSString *)XPath prepareNamespaces:(NSArray *)elementNames error:(NSError **)outError
{
	_XPathContext = xmlXPathNewContext(self.libXMLDocument);
			
	for (NSString *elementName in elementNames) {
	
		// Pull out the namespace prefix from elementName and set the xpath context.
		NSString *prefix = nil;
		NSRange colonRange = [elementName rangeOfString:@":"];
		if (colonRange.location != NSNotFound) {
			prefix = [elementName substringToIndex:colonRange.location];
			
			const xmlChar *namespacePrefix = (xmlChar *)[prefix cStringUsingEncoding:NSUTF8StringEncoding];
			
			// When performing a query for a qualified element name such as geo:lat, libxml
			// requires you to register the namespace. We do so here and pass an empty string
			// as the URL that defines the namespace prefix because there's no way to know
			// what it is given the current API.
			if(xmlXPathRegisterNs(_XPathContext, namespacePrefix, (xmlChar*)"") != 0) {
			
				#ifdef ASPEN_SIMULATOR
				// Logging is useful when running the simulator but inappropriate when running on the device.
				NSLog(@"Failed to register namespace");
				#endif
				
				xmlXPathFreeContext(_XPathContext);
			}
		}
	}
	
    return [self _nodesForXPath:XPath error:outError];
}

static NSArray * childElementsOf(xmlNodePtr a_node, XMLElement *contextElement)
{
    NSMutableArray *childElements = [NSMutableArray array];
    
    xmlNodePtr childrenHeadPtr = a_node->children;
    
    if (!childrenHeadPtr) {
        return childElements;
    }
    
    xmlNode *currentNode = childrenHeadPtr;
    
    while (currentNode) {
    
        if (currentNode->type == XML_ELEMENT_NODE) {
            XMLElement *childElement = [XMLElement elementWithXMLNode:currentNode];
            if (childElement) {
                [childElements addObject:childElement];
            }
        } else if (currentNode->type == XML_TEXT_NODE) {
            XMLNode *childNode = [XMLNode nodeWithXMLNode:currentNode];
            [childElements addObject:childNode];
        }
        
        currentNode = currentNode->next;
    }
    
    return childElements;
}

static NSDictionary *getElementAttributes(xmlNode *node)
{
    if (node->type != XML_ELEMENT_NODE) {
        return nil;
    }
    
    NSMutableDictionary *elementAttributes = [NSMutableDictionary dictionary];
    
    xmlAttr *attributes = node->properties;
    
    while (attributes) {
        
        const xmlChar *attName = attributes->name;
        xmlChar *attValue = xmlGetProp(node, attName);
        
        NSString *attributeName = [XMLUtilities stringWithXMLChar:attName];
        NSString *attributeValue = [XMLUtilities stringWithXMLChar:attValue];
        xmlFree(attValue);
        if (attributeName && attributeValue) {
            [elementAttributes setValue:attributeValue forKey:attributeName];
        }
        
        attributes = attributes->next;
    }
    
	return elementAttributes;
}

#pragma mark -
#pragma mark    XPath Support
#pragma mark -

- (NSArray *)_nodesForXPath:(NSString *)XPath error:(NSError **)outError
{
	xmlDocPtr document = self.libXMLDocument;
	xmlNode *contextNode = self.libXMLNode;
	
	const xmlChar *XPathQuery = (const xmlChar *)[XPath UTF8String];
	
	if (!XPathQuery) {
		if (outError) {
            *outError = [NSError errorWithDomain:XMLParsingErrorDomainString code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"-[XMLElement _nodesForXPath:] XPath argument is nil.", NSLocalizedFailureReasonErrorKey, nil]];
        }
		return nil;
	}
	
	// To execute an XPath query, first create a new XPath context.
	// If the query includes namespace-prefixed elements, 
	// elementsForXPath:prepareNamespaces: might have already set the context.
	
	if (!_XPathContext) {
		_XPathContext = xmlXPathNewContext(document); 
	}
	
	if (!_XPathContext) {
		if (outError) {
            *outError = [NSError errorWithDomain:XMLParsingErrorDomainString code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"-[XMLElement _nodesForXPath:] couldn't create an xmlXPathContext.", NSLocalizedFailureReasonErrorKey, nil]];
        }

		return nil;
	}
	
	_XPathContext->node = contextNode;
	
	// Holds the results of the XPath query.
	xmlXPathObjectPtr queryResults = xmlXPathEvalExpression(XPathQuery, _XPathContext);
	if (!queryResults) {
		if (outError) {
            *outError = [NSError errorWithDomain:XMLParsingErrorDomainString code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"xmlXPathEvalExpression() failed.", NSLocalizedFailureReasonErrorKey, nil]];
        }
		return nil;
	}

	// libxml has returned results from the query.
	// Iterate through them and create XMLElement objects for each.
	NSMutableArray *resultElements = [NSMutableArray array];

    NSUInteger nodeCounter, size = (queryResults->nodesetval) ? queryResults->nodesetval->nodeNr : 0;
    
    for(nodeCounter = 0; nodeCounter < size; ++nodeCounter) {
        xmlNode *nextNode = queryResults->nodesetval->nodeTab[nodeCounter];
        if (!nextNode || nextNode->type != XML_ELEMENT_NODE) {
            continue;
        }
        XMLElement *nextResult = [XMLElement elementWithXMLNode:nextNode];
        [resultElements addObject:nextResult];
    }
    
    xmlXPathFreeObject(queryResults);
    xmlXPathFreeContext(_XPathContext);
	
	return resultElements;
}

#pragma mark -
#pragma mark    Attributes
#pragma mark -

// Return an attribute in the element whose name matches the argument. 
- (NSString *)attributeNamed:(NSString *)name
{
    NSAssert(name != nil, @"-[XMLElement attributeNamed:] 'name' argument is nil.");
    
    return [self.attributes objectForKey:name];
}

// Private method that returns the libxml attribute for the given name.
- (xmlAttr *)_getRawAttributeForName:(NSString *)name
{    
    xmlAttr *attribute = xmlHasProp(self.libXMLNode, [name xmlChar]);
        
    return attribute;
}

// Adds to the element an attribute named 'attributeName' with the value 'attributeValue'.
- (XMLNode *)addAttribute:(NSString *)attributeName value:(NSString *)attributeValue
{
    NSAssert(attributeName != nil, @"-[XMLElement addAttribute:value:] attribute name parameter is nil.");
    NSAssert1([attributeName isKindOfClass:[NSString class]], @"-[XMLElement addAttribute:value:] attribute name is not an NSString.", attributeName);
    
    NSAssert(attributeValue != nil, @"-[XMLElement addAttribute:value:] attribute value parameter is nil.");
    NSAssert1([attributeValue isKindOfClass:[NSString class]], @"-[XMLElement addAttribute:value:] attribute value is not an NSString.", attributeValue);

    xmlAttr *newAttribute = xmlNewProp(self.libXMLNode, [attributeName xmlChar], [attributeValue xmlChar]);
    
    if (newAttribute) {
        return [XMLNode nodeWithXMLNode:(xmlNode *)newAttribute];
    }
    
    return nil;
}

// Deletes from the element the attribute named 'attributeName'.
- (void)deleteAttributeNamed:(NSString *)attributeName
{
    xmlAttr *attribute = [self _getRawAttributeForName:attributeName];
    if (attribute) {
        xmlRemoveProp(attribute);
    }
}

- (NSDictionary *)attributes
{
    return getElementAttributes(self.libXMLNode);
}

// Returns a string representation of the receiver's attributes and their values.
- (NSString *)attributesString
{
    NSMutableString *attributesString = [NSMutableString string];
    for (NSString *attribute in self.attributes) {
        [attributesString appendFormat:@"%@=\"%@\"", attribute, [self.attributes valueForKey:attribute]];
    }
    return attributesString;
}

#pragma mark -
#pragma mark    Mutation
#pragma mark -

// Look at the receiver's children and merge consecutive text nodes into a single node.
- (void)consolidateConsecutiveTextNodes
{    
    NSArray *children = self.children;
    
    for (XMLNode *child in children) {
        
        XMLNode *nextSibling = child.nextSibling;
        if (!nextSibling) {
            break;
        }
        if (child.isTextNode && nextSibling.isTextNode) {
        
            xmlNode *mergedTextNode = xmlTextMerge(child.libXMLNode, nextSibling.libXMLNode);
            
            XMLNode *merged = [XMLNode nodeWithXMLNode:mergedTextNode];
            [self consolidateConsecutiveTextNodes];
            return;
        }
    }
}

// Add a child to the receiver. It will be added as the last child.
- (XMLNode *)addChild:(XMLNode *)node
{
    NSAssert1(node.parent == nil, @"Cannot add a child that already has a parent.", node);

    xmlNode *newNode = xmlAddChild(self.libXMLNode, node.libXMLNode);
    return [XMLNode nodeWithXMLNode:newNode];
}

// Insert a child node at the specified index in the receiver.
- (void)insertChild:(XMLNode *)node atIndex:(NSUInteger)index
{
    NSAssert1(index <= [self childCount], @"-[XMLElement insertChild:atIndex:] index beyond bounds.", [NSNumber numberWithUnsignedInt:index]);
    
    XMLNode *nodeAtIndex = [self childAtIndex:index];
    [nodeAtIndex addNodeAsPreviousSibling:node];
}

// Private method that adds the libxml node to the receiver's children list.
- (XMLNode *)_addRawChild:(xmlNode *)node
{
    NSAssert1(node->parent == NULL, @"Cannot add a child that already has a parent.", node);
    
    xmlNode *newNode = xmlAddChild(self.libXMLNode, node);
    return [XMLNode nodeWithXMLNode:newNode];
}

// Add the string as a text node of the receiver.
- (XMLNode *)addTextChild:(NSString *)text
{
    xmlNode *newTextNode = xmlNewText([text xmlChar]);
    
    if (newTextNode) {
        return [self _addRawChild:newTextNode];
    }
    
    return nil;
}

// Add to the receiver an element named 'childName'.
- (XMLElement *)addChildNamed:(NSString *)childName
{
    return [self addChildNamed:childName withTextContent:nil];
}

// Add to the receiver an element named 'childName' and set the content of the new element to 'nodeContent'.
- (XMLElement *)addChildNamed:(NSString *)childName withTextContent:(NSString *)nodeContent
{
    NSAssert1(childName != nil && [childName length] != 0, @"childName is nil or empty", childName);
    
    xmlNode *newNode = xmlNewTextChild(self.libXMLNode, NULL, [childName xmlChar], [nodeContent xmlChar]);
    
    return [XMLElement elementWithXMLNode:newNode];
}

@end
