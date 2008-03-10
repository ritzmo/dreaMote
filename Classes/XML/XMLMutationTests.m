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

File: XMLMutationTests.m
Abstract: Unit testing support.

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



#import "XMLMutationTests.h"

@implementation XMLMutationTests


- (NSString *)document1
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root></root>";
}

- (NSString *)document2
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><firstChild>First <emphasis>child</emphasis> text.</firstChild></root>";
}

- (NSString *)document3
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><firstChild>First <emphasis>child</emphasis> <important>note!</important> text.</firstChild></root>";
}

- (NSString *)document4
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><firstChild></firstChild><secondChild></secondChild><thirdChild></thirdChild><fourthChild></fourthChild></root>";
}

- (NSString *)document5
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><firstChild></firstChild>Beginning text <secondChild></secondChild> ending text.<thirdChild></thirdChild><fourthChild></fourthChild></root>";
}

- (void)setUp
{
    _parsedDocument1 = [XMLDocument documentWithXMLString:[self document1] error:nil];
    _parsedDocument2 = [XMLDocument documentWithXMLString:[self document2] error:nil];
    _parsedDocument3 = [XMLDocument documentWithXMLString:[self document3] error:nil];
    _parsedDocument4 = [XMLDocument documentWithXMLString:[self document4] error:nil];
    _parsedDocument5 = [XMLDocument documentWithXMLString:[self document5] error:nil];
}

- (void)testCreateChildWithName
{
    XMLElement *newElement = [XMLElement elementWithName:@"child"];
    
    STAssertNotNil(newElement, @"XMLElement elementWithName: failed to return a new element");
    STAssertEqualObjects([newElement name], @"child", @"-[XMLElement elementWithName:] returned the wrong element.");
}

- (void)testAddChildToRootElement
{
    XMLElement *rootElement = _parsedDocument1.rootElement;
    
    XMLElement *newElement = [rootElement addChildNamed:@"child" withTextContent:@"text"];
        
    STAssertNotNil(newElement, @"-[XMLElement addChildElementName:withTextContent:] failed to return the new element.");
    
    NSString *expectedString = @"<child>text</child>";
    STAssertEqualObjects([newElement XMLString], expectedString, @"-[XMLElement addChildElementName:withTextContent:] returned the wrong XML.");
    
    XMLElement *parentElement = [newElement parent];
    STAssertEqualObjects([parentElement name], @"root", @"-[XMLElement addChildElementName:withTextContent:] returned the wrong root element.");
}

- (void)testCreateTextNode
{
    XMLNode *textNode = [XMLNode nodeWithString:@"new text node"];
    
    STAssertNotNil(textNode, @"+[XMLNode nodeWithString:] failed to return a text node.");
    STAssertEqualObjects([textNode stringValue], @"new text node", @"+[XMLNode nodeWithString:] returned a node with the wrong content."); 
}

- (void)testCopyXMLElement
{
    XMLElement *originalRootElement = _parsedDocument2.rootElement;
    XMLElement *rootElementCopy = [originalRootElement copy];
    
    STAssertNotNil(rootElementCopy, @"Failed to create a copy of the root element.");
    STAssertEqualObjects([rootElementCopy XMLString], [originalRootElement XMLString], @"-[XMLElement copy] returned an unexpected value.");
    [rootElementCopy release];
}

// Test that all of the nodes in the document, including whitespace nodes, are included in the children.
- (void)testChildWhitespaceIntegrity
{
    // @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><firstChild>First <emphasis>child</emphasis> <important>note!</important> text.</firstChild></root>";

    NSArray *descendants = _parsedDocument3.rootElement.descendants;
    
    STAssertEquals([descendants count], 8u, @"-[XMLElement descendants] returned the wrong number of nodes.");
    
    NSString *firstNodeXML     = @"<firstChild>First <emphasis>child</emphasis> <important>note!</important> text.</firstChild>";
    NSString *secondNodeXML    = @"First ";
    NSString *thirdNodeXML     = @"<emphasis>child</emphasis>";
    NSString *fourthNodeXML    = @"child";
    NSString *fifthNodeXML     = @" ";
    NSString *sixthNodeXML     = @"<important>note!</important>";
    NSString *seventhNodeXML   = @"note!";
    NSString *eighthNodeXML    = @" text.";
    
    STAssertEqualObjects([[descendants objectAtIndex:0] XMLString], firstNodeXML, @"-[XMLElement descendants] returned wrong first node.");
    STAssertEqualObjects([[descendants objectAtIndex:1] XMLString], secondNodeXML, @"-[XMLElement descendants] returned wrong second node.");
    STAssertEqualObjects([[descendants objectAtIndex:2] XMLString], thirdNodeXML, @"-[XMLElement descendants] returned wrong third node.");
    STAssertEqualObjects([[descendants objectAtIndex:3] XMLString], fourthNodeXML, @"-[XMLElement descendants] returned wrong fourth node.");
    STAssertEqualObjects([[descendants objectAtIndex:4] XMLString], fifthNodeXML, @"-[XMLElement descendants] returned wrong fifth node.");
    STAssertEqualObjects([[descendants objectAtIndex:5] XMLString], sixthNodeXML, @"-[XMLElement descendants] returned wrong sixth node.");
    STAssertEqualObjects([[descendants objectAtIndex:6] XMLString], seventhNodeXML, @"-[XMLElement descendants] returned wrong seventh node.");
    STAssertEqualObjects([[descendants objectAtIndex:7] XMLString], eighthNodeXML, @"-[XMLElement descendants] returned wrong eighth node.");
}

- (void)testAddElementAsNextSibling
{
    XMLElement *originalRootElement = _parsedDocument3.rootElement;
    XMLElement *rootElementCopy = [originalRootElement copy];
    
    XMLElement *contextElement = (XMLElement *)[rootElementCopy childAtIndex:0];
    [contextElement addNodeAsNextSibling:[XMLElement elementWithName:@"newSibling"]];
        
    NSString *expectedXML = @"<root><firstChild>First <emphasis>child</emphasis> <important>note!</important> text.</firstChild><newSibling></newSibling></root>";
    STAssertEqualObjects([rootElementCopy XMLString], expectedXML, @"-[XMLElement addNodeAsNextSibling:] failed.");
    
    [rootElementCopy release];
}

- (void)testAddElementAsPreviousSibling
{
    XMLElement *originalRootElement = _parsedDocument3.rootElement;
    XMLElement *rootElementCopy = [originalRootElement copy];
    
    XMLElement *contextElement = (XMLElement *)[rootElementCopy childAtIndex:0];
    [contextElement addNodeAsPreviousSibling:[XMLElement elementWithName:@"newSibling"]];
        
    NSString *expectedXML = @"<root><newSibling></newSibling><firstChild>First <emphasis>child</emphasis> <important>note!</important> text.</firstChild></root>";
    STAssertEqualObjects([rootElementCopy XMLString], expectedXML, @"-[XMLElement addNodeAsPreviousSibling:] failed.");
    
    [rootElementCopy release];
}

- (void)testAddTextChild
{
    XMLElement *root = [_parsedDocument1.rootElement copy];
    [root addTextChild:@"new text child"];
    
    NSString *expectedXML = @"<root>new text child</root>";
    STAssertEqualObjects([root XMLString], expectedXML, @"-[XMLElement addTextChild:]");
    
    [root release];
}

- (void)testInsertChildAtIndex
{   
    XMLElement *originalRootElement = _parsedDocument4.rootElement;
    XMLElement *rootElementCopy = [originalRootElement copy]; // Create a copy so we don't modified the original document in case other tests want to use it.
    
    [rootElementCopy insertChild:[XMLElement elementWithName:@"newSibling"] atIndex:1];
    
    // Original: <root><firstChild></firstChild><secondChild></secondChild><thirdChild></thirdChild><fourthChild></fourthChild></root>
    // We're inserting <newSibling/> at index 1, which should push <secondChild> to index 2.
    NSString *expectedXML = @"<root><firstChild></firstChild><newSibling></newSibling><secondChild></secondChild><thirdChild></thirdChild><fourthChild></fourthChild></root>";
    STAssertEqualObjects([rootElementCopy XMLString], expectedXML, @"-[XMLElement insertChild:atIndex:] failed.");
    
    [rootElementCopy release];
}

- (void)testDeleteElement
{
    XMLElement *originalRootElement = _parsedDocument4.rootElement;
    XMLElement *rootElementCopy = [originalRootElement copy]; // Create a copy so we don't modified the original document in case other tests want to use it.

    XMLElement *secondChild = [rootElementCopy firstChildNamed:@"secondChild"];
    
    [secondChild detach];
    
    NSString *expectedXML = @"<root><firstChild></firstChild><thirdChild></thirdChild><fourthChild></fourthChild></root>";
    STAssertEqualObjects([rootElementCopy XMLString], expectedXML, @"-[XMLElement detach] failed.");
}

- (void)testDeleteEmbeddedElementConsolidateTextNodes
{
    // Delete an element that's surrounded by text nodes and verify that the text nodes are intact.
    // Then consolidate the text nodes.
    
    XMLElement *originalRootElement = _parsedDocument5.rootElement;
    XMLElement *rootElementCopy = [originalRootElement copy]; // Create a copy so we don't modified the original document in case other tests want to use it.

    XMLElement *secondChild = [rootElementCopy firstChildNamed:@"secondChild"];
    
    [secondChild detach];
    
    NSString *expectedXML = @"<root><firstChild></firstChild>Beginning text  ending text.<thirdChild></thirdChild><fourthChild></fourthChild></root>";
    STAssertEqualObjects([rootElementCopy XMLString], expectedXML, @"-[XMLElement detach] failed.");
    
    // Before consolidateConsecutiveTextNodes, there are 5 descendants of the root element.
    [rootElementCopy consolidateConsecutiveTextNodes];
    
    // After consolidateConsecutiveTextNodes, there should be 4 descendants of the root element.
    // Two two consecutive text nodes, 'Beginning text ' and ' ending text.' should have been combined.
    STAssertEquals([rootElementCopy.descendants count], 4u, @"-[XMLElement consolidateConsecutiveTextNodes] failed.");
    
    XMLNode *consolidatedTextNode = [rootElementCopy childAtIndex:1];
    
    NSString *expectedString = @"Beginning text  ending text.";
    STAssertEqualObjects([consolidatedTextNode XMLString], expectedString, @"-[XMLElement consolidateConsecutiveTextNodes] returned an unexpected value.");
}

- (void)testAddAttribute
{
    XMLElement *newElement = [XMLElement elementWithName:@"element"];
    [newElement addAttribute:@"attribute" value:@"value"];
    
    NSString *expectedXML = @"<element attribute=\"value\"></element>";
    STAssertEqualObjects([newElement XMLString], expectedXML, @"-[XMLElement addAttribute:value:] failed.");
}

- (void)testRemoveAttribute
{
    XMLDocument *document = [XMLDocument documentWithXMLString:@"<element attribute=\"value\"></element>" error:nil];
    
    [[document rootElement] deleteAttributeNamed:@"attribute"];
    
    NSString *expectedXML = @"<element></element>";
    STAssertEqualObjects([[document rootElement] XMLString], expectedXML, @"-[XMLElement deleteAttributeNamed] failed.");
}

@end
