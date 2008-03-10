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

File: XMLReaderSAX.h
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



#import <Foundation/Foundation.h>

#import "XMLReader.h"
#import "XMLModelObject.h"
#import <libxml/xmlstring.h>

/*
    This class implements a streaming XML parser on top of the libxml SAX API.
    It provides facilities that let you associate your application's model
    objects with content in the XML document. When the parser encounters an element,
    it looks up the element name in the currentModelObject dictionary, which provides
    a mapping of element names to model object class names. If the dictionary 
    contains an entry for the element name, XMLReaderSAX instantiates an object of that
    class and sets it as the currentModelObject.
    
    For example, in this sample application, the model class is Earthquake, and the 
    corresponding element in the XML document is 'item'. Before beginning the parse,
    the client sets the modelObjectDictionary:
    
    NSDictionary *modelDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Earthquake", @"item", nil];
    XMLReaderSAX *streamingParser = [[XMLReaderSAX alloc] init];
    [streamingParser setModelObjectDictionary:modelDictionary];
    
    When the parser finds an "item" element, it calls -objectForKey:@"item" on the model dictionary,
    which in this case returns the string 'Earthquake'. The parser then instantiates an Earthquake
    object and sets it as the currentModelObject.
    
    If the startElementSAX callback finds attributes in the element, it calls -setXMLAttributes on
    the instantiated model object.
    
    When the startElementSAX callback finds an element that does not have an entry in the model
    object dictionary, it looks at the class of the current model object (assuming there is one)
    and calls the class method +childElements. If the current element is in the childElements 
    dictionary, the contents of the current element are set as the value of a corresponding property
    in the model object. That property name is determined by looking at the class's propertyNamesAndChildElementNames
    dictionary whose keys are element names and values are strings that represent the property
    in the model object that should hold the child element's content.
    
    For example, in the RSS feed of this application, the "item" elements have a "title" child:
        <item><title>M 2.6, Southern California</title></item>
        
    When the 'title' element is encountered, the currentModelObject is an Earthquake object,
    and the Earthquake class has a propertyNamesAndChildElementNames method that returns this dicitionary:
    [NSDictionary dictionaryWithObjectsAndKeys:@"Latitude", kLatitudeElementName, @"Longitude", kLongitudeElementName, @"Title", kTitleElementName, @"EventDescription", kDescriptionElementName, @"WebLink", kLinkElementName, nil]

    The string constant kTitleElementName has the value 'title', so calling objectForKey:@"title" on the
    propertyNamesAndChildElementNames dictionary returns the string "Title". XMLReaderSAX constructs an Objective-C
    selector from that string (the selector is a setter method for the 'title' property, 'setTitle:') and then invokes
    that method on the Earthquake object to store the value of the 'title' XML element.

*/

@interface XMLReaderSAX : XMLReader {

@private
    id _currentModelObject;
    NSDictionary *_modelObjectDictionary;
    NSMutableArray *_parsedModelObjects;
    NSMutableString *_currentElementContent;
    
    NSString *_childElementSetterSelectorName;
}

@property (nonatomic, retain) id currentModelObject;
@property (nonatomic, retain) NSDictionary *modelObjectDictionary;
@property (nonatomic, retain) NSMutableArray *parsedModelObjects;
@property (nonatomic, retain) NSMutableString *currentElementContent;
@property (nonatomic, retain) NSString *childElementSetterSelectorName;

- (void)parseXML:(const char *)XMLString parseError:(NSError **)parseError;
- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

- (void)releaseModelObjects;

@end
