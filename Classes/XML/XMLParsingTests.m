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

File: XMLParsingTests.m
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



#import "XMLParsingTests.h"

#import "XMLReader.h"
#import "XMLReaderSAX.h"
#import "XMLDocument.h"
#import "XMLUtilities.h"

@implementation XMLParsingTests

- (NSString *)validXMLDocumentForTesting
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A Title.</title><subdocument><section>Apples.</section><section>Oranges.</section><section>Guavas.</section></subdocument></document>";
}

- (NSString *)validXMLDocumentForTesting2
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A <embedded/> Title.</title><subdocument><section>Apples.</section><section>Oranges.</section><section>Guavas.</section></subdocument></document>";
}

- (NSString *)XPathDocumentForTesting
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A Title.</title><subdocument><section><title>Inner Title</title>Apples.</section><section>Oranges.</section><section>Guavas.</section></subdocument></document>";
}

- (NSString *)malformedXMLDocumentForTesting
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document<title>A Title.</title><subdocument><section></section><section></section><sectection></subdocument></document>";
}

- (NSString *)namespacesXML
{
    // The namespaces here aren't defined, but that's okay. We're just testing whether or not they interfere with document navigation and queries.
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A Title.</title><apple:subdocument><section>Apples.</section><section>Oranges.</section><orange:section>Guavas.</orange:section></apple:subdocument></document>";
} 

- (NSString *)attributesXML
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title name=\"Banana\">A Title.</title><xml:subdocument><section>Apples.</section><section flavor=\"sweet\">Oranges.</section><section flavor=\"sour\">Papaya.</section><xml:section>Guavas.</xml:section></xml:subdocument></document>";
} 

- (NSString *)nextPreviousXML
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A Title.</title><chapter><section/><section><para/></section></chapter></document>";
}

- (NSString *)nextNodeXML
{
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><title>A Title.<book/>More Text.</title><chapter><section/><section><para/></section></chapter></document>";
}

/*
    Parsing a well-formed document should succeed.
    Parsing a malformed document should fail.
    Parsing a well-formed document with UTF-8 characters should succeed.
*/

- (void)setUp
{
    _parsedDocument1 = [XMLDocument documentWithXMLString:[self validXMLDocumentForTesting] error:nil];
    _parsedDocument2 = [XMLDocument documentWithXMLString:[self namespacesXML] error:nil];
    _parsedDocument3 = [XMLDocument documentWithXMLString:[self attributesXML] error:nil];
    _parsedDocument4 = [XMLDocument documentWithXMLString:[self nextPreviousXML] error:nil];
    _parsedDocument5 = [XMLDocument documentWithXMLString:[self validXMLDocumentForTesting2] error:nil];
    _parsedDocument6 = [XMLDocument documentWithXMLString:[self nextNodeXML] error:nil];
    _parsedDocument7 = [XMLDocument documentWithXMLString:[self XPathDocumentForTesting] error:nil];
}

- (void)tearDown
{

}

- (void)testSAXParseDocument
{
    NSString *XML = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><document><item date=\"today\">A Title.<book/>More Text.</item><chapter><section/><section><para/></section></chapter></document>";

    const char *XMLChars = [XML UTF8String];
    
    NSDictionary *modelDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Earthquake", @"item", nil];
    
    XMLReaderSAX *streamingParser = [[XMLReaderSAX alloc] init];
    [streamingParser setModelObjectDictionary:modelDictionary];
    
    [streamingParser parseXML:XMLChars parseError:nil];
    
    id <XMLModelObject> parsedModelObject = [streamingParser.parsedModelObjects lastObject];
    NSDictionary *attributes = [parsedModelObject XMLAttributes];
    NSString *attributeValue = [attributes valueForKey:@"date"];
    STAssertEqualObjects(attributeValue, @"today", @"XMLReaderSAX failed to find attributes.");
}

- (void)testParseDocument
{
    XMLDocument *parsedDocument = _parsedDocument1;
        
    // We can't use STAssertNotNil when comparing a non-Obj-C object.
    if (!parsedDocument.xmlDocument) {
        STFail(@"The xmlDocPtr of the parsed document is nil, which probably means that the parse failed.");
    }    
}

- (void)testParseMalformedDocument
{
    NSError *error = nil;
    XMLDocument *document = [XMLDocument documentWithXMLString:[self malformedXMLDocumentForTesting] error:&error];
    STAssertNil(document, @"XMLDocument unexpectedly returned a document object when parsing a malformed document.");
    STAssertNotNil(error, @"XMLDocument failed to return an NSError when parsing a malformed document.");
    
    NSString *errorDomain = [error domain];
    STAssertEqualObjects(errorDomain, @"XMLParsingErrorDomain", @"XMLDocument failed to return the expected NSError domain when parsing a malformed document.");
    
}

- (void)testRootElement
{
    XMLElement *rootElement = [_parsedDocument1 rootElement];
    
    NSUInteger childCount = [rootElement childCount];
    if (childCount != 2) {
        // Children of the root element, document, are title and subdocument.
        STAssertEquals(childCount, 2, @"-[XMLElement childCount] returned the wrong value.");
    }
}

- (void)testChildrenNamed
{
     // There are no direct 'section' children of the root element...
    NSArray *sectionChildren = [[_parsedDocument1 rootElement] childrenNamed:@"section"];
    STAssertEquals([sectionChildren count], 0u, @"-[XMLElement childrenNamed] returend the wrong number of 'section' children.");
}

- (void)testDescendantsNamed
{
    // ... though there are 'section' descendants of the root element.
    NSArray *sectionDescendants = [[_parsedDocument1 rootElement] descendantsNamed:@"section"];
    STAssertEquals([sectionDescendants count], 3u, @"-[XMLElement descendantsNamed] returned the wrong number of 'section' sectionDescendants.");
}

- (void)testFirstDescendantNamed
{
    XMLElement *firstDescendantNamed = [[_parsedDocument1 rootElement] firstDescendantNamed:@"section"];
    NSString *content = firstDescendantNamed.stringValue;
    STAssertEqualObjects(content, @"Apples.", @"-[XMLElement firstDescendantNamed:] didn't return the correct element.");
}

- (void)testChildrenNamedWithNamespaces
{
     // There are no direct 'section' children of the root element...
    NSArray *sectionChildren = [[_parsedDocument2 rootElement] childrenNamed:@"section"];
    STAssertEquals([sectionChildren count], 0u, @"-[XMLElement childrenNamed] returend the wrong number of 'section' children.");
}

- (void)testDescendantsNamedWithNamespaces
{
    // ... though there are 'section' descendants of the root element.
    NSArray *sectionDescendants = [[_parsedDocument2 rootElement] descendantsNamed:@"section"];
    STAssertEquals([sectionDescendants count], 3u, @"-[XMLElement descendantsNamed] returned the wrong number of 'section' sectionDescendants.");
}

- (void)testFirstDescendantNamedWithNamespaces
{
    XMLElement *firstDescendantNamed = [[_parsedDocument2 rootElement] firstDescendantNamed:@"section"];
    NSString *content = firstDescendantNamed.stringValue;
    STAssertEqualObjects(content, @"Apples.", @"-[XMLElement firstDescendantNamed:] didn't return the correct element.");
}

- (void)testParent
{
    XMLElement *firstDescendantNamed = [[_parsedDocument1 rootElement] firstDescendantNamed:@"section"];
    XMLElement *parent = [firstDescendantNamed parent];
    STAssertEqualObjects([parent name], @"subdocument", @"-[XMLElement parent] did not return the correct parent.");
}

- (void)testAttributes
{
    // Get the attributes of the first child of the root element.
    XMLElement *titleChild = [[_parsedDocument3 rootElement] firstChildNamed:@"title"];
    NSDictionary *attributes = [titleChild attributes];
    NSString *nameAttribute = [attributes valueForKey:@"name"];
    STAssertNotNil(nameAttribute, @"-[XMLElement attributes] failed to return a the 'name' attribute.");
    STAssertEqualObjects(@"Banana", nameAttribute, @"-[XMLElement attributes] failed to return the correct value for the 'name' attribute.");
}

- (void)testAttributeQueries
{
    // Use an XPath query to find an attribute with a given name.
        
    NSArray *matchingElements = [[_parsedDocument3 rootElement] elementsWithAttributeNamed:@"flavor"];
    XMLElement *matchingElement = [matchingElements objectAtIndex:0];
    STAssertNotNil(matchingElement, @"-[XMLElement elementsWithAttributeNamed:] failed to return an element for the attribute query.");
   
    // An element was returned. Is it the correct element?
    NSString *elementName = matchingElement.name;
    NSDictionary *attributes = [matchingElement attributes];
    STAssertEqualObjects(elementName, @"section", @"-[XMLElement elementsWithAttributeNamed:] failed to return the correct element for the attribute query.");
    
    NSString *attributeName = [attributes valueForKey:@"flavor"];
    STAssertNotNil(attributeName, @"-[XMLElement elementsWithAttributeNamed:] failed to return the expected attribute.");
    STAssertEqualObjects(attributeName, @"sweet", @"-[XMLElement elementsWithAttributeNamed:] failed to return the correct attribute value.");
}

- (void)testAttributeQueries2
{
    // Use an XPath query to find an attribute with a given name and value.
    NSArray *matchingElements = [[_parsedDocument3 rootElement] elementsWithAttributeNamed:@"flavor" attributeValue:@"sour"];
    XMLElement *matchingElement = [matchingElements objectAtIndex:0];
    STAssertNotNil(matchingElement, @"-[XMLElement elementsWithAttributeNamed:attribueValue:] failed to return an element for the attribute query.");
    
    // An element was returned. Is it the correct element?
    NSString *elementName = matchingElement.name;
    NSDictionary *attributes = [matchingElement attributes];
    STAssertEqualObjects(elementName, @"section", @"-[XMLElement elementsWithAttributeNamed:attribueValue:] failed to return the correct element for the attribute query.");
    
    NSString *attributeName = [attributes valueForKey:@"flavor"];
    STAssertNotNil(attributeName, @"-[XMLElement elementsWithAttributeNamed:] failed to return the expected attribute.");
    STAssertEqualObjects(attributeName, @"sour", @"-[XMLElement elementsWithAttributeNamed:attribueValue:] failed to return the correct attribute value.");
    
}

- (void)testArbitraryXPathQuery
{
    // Execute an arbitrary XPath query and test the results.
    NSArray *matchingElements = [[_parsedDocument1 rootElement] elementsForXPath:@"//section[last()]" error:nil];
    XMLElement *matchedElement = [matchingElements objectAtIndex:0];
    STAssertNotNil(matchedElement, @"-[XMLElement elementsForXPath:error:] failed to return an element for XPath query.");
    
    NSString *content = matchedElement.stringValue;
    STAssertEqualObjects(content, @"Guavas.", @"-[XMLElement elementsForXPath:error:] failed to return the correct element for XPath query.");
}

- (void)testCompoundXPathQuery
{    
    // Return all of the title elements in the document (//document//title)
    // and the subdocument children of the 'document' element
    // and the second-to-last section descendant in the document.

    NSArray *elements = [[_parsedDocument7 rootElement] elementsForXPath:@"//document//title | //document/subdocument | //section[last()-1]" error:nil];
    STAssertEquals([elements count], 4u, @"-[XMLElement elementsForXPath:error:] returned the wrong number of nodes.");
    
    XMLElement *firstResult, *secondResult, *thirdResult, *fourthResult;
    firstResult = [elements objectAtIndex:0];
    secondResult = [elements objectAtIndex:1];
    thirdResult = [elements objectAtIndex:2];
    fourthResult = [elements objectAtIndex:3];
    
    STAssertEqualObjects([firstResult name], @"title", @"Unexpected first element returned.");
    STAssertEqualObjects([firstResult XMLString], @"<title>A Title.</title>", @"Unexpected first element returned.");
    
    STAssertEqualObjects([secondResult name], @"subdocument", @"Unexpected second element returned.");
    STAssertEqualObjects([secondResult XMLString], @"<subdocument><section><title>Inner Title</title>Apples.</section><section>Oranges.</section><section>Guavas.</section></subdocument>", @"Unexpected second element returned.");
    
    STAssertEqualObjects([thirdResult name], @"title", @"Unexpected third element returned.");
    STAssertEqualObjects([thirdResult XMLString], @"<title>Inner Title</title>", @"Unexpected third element returned.");
    
    STAssertEqualObjects([fourthResult name], @"section", @"Unexpected fourth element returned.");
    STAssertEqualObjects([fourthResult XMLString], @"<section>Oranges.</section>", @"Unexpected fourth element returned.");
}

- (void)testNextNodeNavigation
{   
    // <document><title>A Title.<book/>More Text.</title><chapter><section/><section><para/></section></chapter></document>
    // The next node in the tree when the context element is the title element is the title element's text node.
    // Make sure nextNode returns that.
    XMLElement *titleElement = [[_parsedDocument6 rootElement] firstChildNamed:@"title"];
    XMLNode *nextNode = [titleElement nextNode];
    STAssertNotNil(nextNode, @"-[XMLElement nextNode] returned nothing.");
    STAssertEqualObjects([nextNode XMLString], @"A Title.", @"-[XMLElement nextNode] returned the wrong value.");
    
    // If the text node 'A Title.' is the context node, nextNode should return the book element.
    XMLElement *bookElement = (XMLElement *)[nextNode nextNode];
    STAssertNotNil(nextNode, @"-[XMLElement nextNode] returned nothing when the context node is a text node.");
    STAssertEqualObjects([bookElement name], @"book", @"-[XMLElement nextNode] returned the wrong element when the context node is a text node.");
    
    XMLNode *textAfterBook = [bookElement nextNode];
    STAssertNotNil(textAfterBook, @"-[XMLElement nextNode] returned nothing when the context node is an embedded element.");
    STAssertEqualObjects([textAfterBook XMLString], @"More Text.", @"-[XMLElement nextNode] returned the wrong node when the context node is an embedded element.");
    
    XMLElement *elementAfterBook = (XMLElement *)[textAfterBook nextNode];
    STAssertNotNil(elementAfterBook, @"-[XMLElement nextNode] returned nothing when the context node is a text node and is the last child.");
    STAssertEqualObjects([elementAfterBook name], @"chapter", @"-[XMLElement nextNode] returned the wrong element when the context node is a text node and is the last child.");
}

- (void)testPreviousNodeNavigation
{
    // <document><title>A Title.<book/>More Text.</title><chapter><section/><section><para/></section></chapter></document>
    XMLElement *titleElement = [[_parsedDocument6 rootElement] firstChildNamed:@"title"];
    XMLNode *lastChildOfTitle = [titleElement lastChild];
    STAssertEqualObjects([lastChildOfTitle XMLString], @"More Text.", @"-[XMLElement lastChild] returned the wrong node.");
    
    XMLElement *previousElement = (XMLElement *)[lastChildOfTitle previousNode];
    STAssertNotNil(previousElement, @"-[XMLNode previousNode] returned a nil element. Should have returned the 'book' element.");
    STAssertEqualObjects([previousElement name], @"book", @"-[XMLNode previousNode] failed to return the 'book' element.");
    
    // Now get the previous node of the title element, which is the document element.
    XMLElement *documentElement = (XMLElement *)[titleElement previousNode];
    STAssertNotNil(documentElement, @"-[XMLElement previousNode] failed to return a node.");
    STAssertEqualObjects([documentElement name], @"document", @"-[XMLNode previousNode] failed to return the 'document' element.");
}

- (void)testNextSiblingNavigation
{
    XMLElement *titleElement = [[_parsedDocument4 rootElement] firstChildNamed:@"title"];
    XMLElement *nextElement = (XMLElement *)[titleElement nextSibling];
    STAssertNotNil(nextElement, @"-[XMLElement nextSibling] failed to return an element.");
    
    NSString *nextElementName = nextElement.name;
    STAssertEqualObjects(nextElementName, @"chapter", @"-[XMLElement nextSibling] failed to return the correct element.");
}

- (void)testPreviousSiblingNavigation
{
    XMLElement *chapterElement = [[_parsedDocument4 rootElement] firstChildNamed:@"chapter"];
    XMLElement *previousSibling = (XMLElement *)[chapterElement previousSibling];
    STAssertNotNil(previousSibling, @"-[XMLElement previousSibling] failed to return an element.");
    
    NSString *previousSiblingName = previousSibling.name;
    STAssertEqualObjects(previousSiblingName, @"title", @"-[XMLElement previousSibling] failed to return the correct element.");
}

- (void)testChildrenNavigation
{
    // <title>A <embedded/> Title.</title>
    XMLElement *titleElement = [[_parsedDocument5 rootElement] firstChildNamed:@"title"];
    NSArray *titleChildren = [titleElement children];
    XMLNode *firstChild = [titleChildren objectAtIndex:0];
    XMLElement *secondChild = [titleChildren objectAtIndex:1];
    XMLNode *thirdChild = [titleChildren objectAtIndex:2];
    
    STAssertEqualObjects([firstChild XMLString], @"A ", @"-[XMLElement children] failed to return the expected node as the first child.");
    STAssertEqualObjects([secondChild name], @"embedded", @"-[XMLElement children] failed to return the expected node as the second child.");
    STAssertEqualObjects([thirdChild XMLString], @" Title.", @"-[XMLElement children] failed to return the expected node as the first child.");
}

- (void)testChildrenNavigation2
{
    // Test an XPath query when the context node is not the root elemetn.
    // <title>A <embedded/> Title.</title>
    XMLElement *titleElement = [[_parsedDocument5 rootElement] firstChildNamed:@"subdocument"];
    NSArray *sectionChildren = [titleElement childrenNamed:@"section"];
    
    STAssertEquals(3u, [sectionChildren count], @"-[XMLElement childrenNamed:] returned the wrong number of children.");
    
    XMLElement *firstChild = [sectionChildren objectAtIndex:0];
    XMLElement *secondChild = [sectionChildren objectAtIndex:1];
    XMLElement *thirdChild = [sectionChildren objectAtIndex:2];
    
    STAssertEqualObjects([firstChild stringValue], @"Apples.", @"-[XMLElement children] failed to return the expected node as the first child.");
    STAssertEqualObjects([secondChild stringValue], @"Oranges.", @"-[XMLElement children] failed to return the expected node as the second child.");
    STAssertEqualObjects([thirdChild stringValue], @"Guavas.", @"-[XMLElement children] failed to return the expected node as the first child.");

}

- (void)testRootElementLink
{
    // Test to make sure the pointer back to the root element is intact.
    XMLElement *titleElement = [[_parsedDocument4 rootElement] firstChildNamed:@"title"];
    XMLElement *root = titleElement.rootElement;
    STAssertNotNil(root, @"XMLElement.rootElement failed to return an element.");
    
    NSString *rootElementName = root.name;
    STAssertEqualObjects(rootElementName, @"document", @"XMLElement.rootElement returned the wrong element.");
}

- (void)testXMLString
{
    // Test the results of calling -XMLString on an element.
    NSString *rawXMLString = [[_parsedDocument3 rootElement] XMLString];
    NSString *expectedResult = @"<document><title name=\"Banana\">A Title.</title><xml:subdocument><section>Apples.</section><section flavor=\"sweet\">Oranges.</section><section flavor=\"sour\">Papaya.</section><xml:section>Guavas.</xml:section></xml:subdocument></document>";
    
    STAssertEqualObjects(rawXMLString, expectedResult, @"-[XMLElement XMLString] returned an unexpected value.");
}

- (void)testIndex
{
    XMLElement *chapterElement = [[_parsedDocument4 rootElement] firstChildNamed:@"chapter"];
    NSInteger chapterIndex = [chapterElement index];
    
    STAssertEquals(chapterIndex, 1, @"-[XMLNode index] returned the wrong index."); 
}

@end
