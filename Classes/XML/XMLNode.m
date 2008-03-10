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

File: XMLNode.m
Abstract: A text node in an XML document.

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



#import "XMLNode.h"
#import "XMLElement.h"
#import "XMLUtilities.h"

@implementation XMLNode

@synthesize libXMLNode = _libXMLNode;
@synthesize libXMLDocument = _libXMLDocument;
@synthesize parent;
@synthesize nextNode;
@synthesize nextSibling;
@synthesize previousNode;
@synthesize previousSibling;
@synthesize XMLString;
@synthesize stringValue;
@synthesize rootElement;

+ (XMLNode *)nodeWithXMLNode:(xmlNode *)nodeWithXMLNode
{
    if (nodeWithXMLNode->type != XML_TEXT_NODE) {
        return nil;
    }

    XMLNode *node = [[[self class] alloc] initWithXMLNode:nodeWithXMLNode];
    
    return [node autorelease];
}

+ (XMLNode *)nodeWithString:(NSString *)string
{
    xmlNode *newNode = xmlNewText([string xmlChar]);
    
    return [[self class] nodeWithXMLNode:newNode];
}

- (id)initWithXMLNode:(xmlNode *)node
{
    self = [super init];
    
    if (self) {
        self.libXMLNode = node;
    }
    
    return self;
}

- (NSString *)description
{
    return [self XMLString];
}

- (NSString *)XMLString
{
    return [NSString stringWithFormat:@"%@", self.stringValue];
}

- (NSString *)stringValue
{
    NSString *stringValue = nil;
    xmlChar *nodeContent = xmlNodeGetContent(self.libXMLNode);
    stringValue = [XMLUtilities stringWithXMLChar:nodeContent];
    xmlFree(nodeContent);
    return stringValue;
}

- (XMLNodeKind)kind
{
    return XMLNodeTextKind;
}

- (BOOL)isTextNode
{
    return self.kind == XMLNodeTextKind;
}

- (BOOL)isElementNode
{
    return self.kind == XMLNodeElementKind;
}

#pragma mark -
#pragma mark    Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
    id newElement = [[[self class] alloc] initWithXMLNode:self.libXMLNode];
    
    return newElement;
}

#pragma mark -
#pragma mark    Navigation
#pragma mark -

- (XMLElement *)rootElement
{
    // Iterate back through the tree by looking at the parent of the current node.
    // The node that doesn't have a parent is the root element.
    XMLElement *root = nil;
    XMLElement *parentNode = (XMLElement *)self;
    while (parentNode = [parentNode parent]) {
        root = parentNode;
    }
    return root;
}

- (XMLNode *)nextNode
{
    XMLNode *nextNode = [self nextSibling];
    
    if (nextNode) {
        return nextNode;
    }
    
    // If the node doesn't have a nextNode, its next node is its parent's nextSibling.
    xmlNode *next = self.libXMLNode->parent->next;
    
    return [XMLElement elementWithXMLNode:next];
}
    
- (XMLNode *)nextSibling
{
    xmlNode *nextSibling = self.libXMLNode->next;
    
    if (!nextSibling) {
        return nil;
    }
    
    if (nextSibling->type == XML_ELEMENT_NODE) {
        return [XMLElement elementWithXMLNode:nextSibling];
    }
    return [XMLNode nodeWithXMLNode:nextSibling];
}

- (XMLNode *)previousNode
{
    XMLNode *previousNode = [self previousSibling];
    
    if (previousNode) {
        return previousNode;
    }
    
    // If the node doesn't have a previous sibling, its previous node is its parent.
    return [self parent];
}

- (XMLNode *)previousSibling
{
    xmlNode *previousSibling = self.libXMLNode->prev;
    
    if (!previousSibling) {
        return nil;
    }
    
    if (previousSibling->type == XML_ELEMENT_NODE) {
        return [XMLElement elementWithXMLNode:previousSibling];
    }
    return [XMLNode nodeWithXMLNode:previousSibling];
}

- (XMLElement *)parent
{
    return [XMLElement elementWithXMLNode:self.libXMLNode->parent];
}

- (NSInteger)index
{
    XMLElement *parent = [self parent];
    if (!parent) {
        return NSNotFound; // The node is not in the tree.
    }

    unsigned counter = 0;
    for (XMLNode *child in [parent children]) {
        if ([child isEqual:self]) {
            return counter;
        }
        counter++;
    }
    
    return NSNotFound;
}

#pragma mark -
#pragma mark    Mutation
#pragma mark -

- (void)detach
{
    // Remove the node from the tree. Doesn't free it.
    xmlUnlinkNode(self.libXMLNode);
}

- (void)addNodeAsNextSibling:(XMLNode *)node
{
    xmlAddNextSibling(self.libXMLNode, node.libXMLNode);
}

- (void)addNodeAsPreviousSibling:(XMLNode *)node
{
    xmlAddPrevSibling(self.libXMLNode, node.libXMLNode);
}

#pragma mark -
#pragma mark    Equality
#pragma mark -

- (BOOL)isEqual:(XMLNode *)otherNode
{
    return (self.libXMLNode == otherNode.libXMLNode);
}

@end
