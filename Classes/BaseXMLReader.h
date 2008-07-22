/*

File: XMLReader.h
Abstract: Uses NSXMLParser to extract the contents of an XML file and map it
Objective-C model objects.

Version: 1.7

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <Foundation/Foundation.h>

/*
    This class uses NSXMLParser to map the contents of an XML document to Objective-C model objects.
    It encodes specific knowledge of the XML document being parsed in this sample, which is provided
    by the U.S. Geological Survey at this URL: http://earthquake.usgs.gov/eqcenter/catalogs/7day-M2.5.xml
    
    This sample parses that particular XML file, so you'll need to change it
    to work with the XML document your application uses. 
 
    The USGS RSS feed includes all recent magnitude 2.5 and greater earthquakes world-wide, 
    and represents each earthquake with an <entry> element, such as this:
 
    <entry>
        <id>urn:earthquake-usgs-gov:us:2008rkbc</id>
        <title>M 5.8, Banda Sea</title>
        <updated>2008-04-29T19:10:01Z</updated>
        <link rel="alternate" type="text/html" href="/eqcenter/recenteqsww/Quakes/us2008rkbc.php"/>
        <link rel="related" type="application/cap+xml" href="/eqcenter/catalogs/cap/us2008rkbc"/>
        <summary type="html">
            <img src="http://earthquake.usgs.gov/images/globes/-5_130.jpg" alt="6.102&#176;S 127.502&#176;E" align="left" hspace="20" /><p>Tuesday, April 29, 2008 19:10:01 UTC<br>Wednesday, April 30, 2008 04:10:01 AM at epicenter</p><p><strong>Depth</strong>: 395.20 km (245.57 mi)</p>
        </summary>
        <georss:point>-6.1020 127.5017</georss:point>
        <georss:elev>-395200</georss:elev>
        <category label="Age" term="Past hour"/>
    </entry>
 
    When NSXMLParser encounters an <entry> element, it invokes the delegate method parser:didStartElement:namespaceURI:qualifiedName:attributes:.
    This sample's implementation of that method instantiates an instance of the Earthquake class and adds it to the list of objects
    that the application's delegate manages.
 
    When NSXMLParser reports an element other than an <entry> element, in parser:didStartElement:namespaceURI:qualifiedName:attributes:
    this sample allocates an NSMutableString and sets the contentOfCurrentEarthquakeProperty property, which is used to hold
    the content of child elements of the current <entry> element.
 
    For example, if the current element is <title>, the sample creates a mutable string for the contentOfCurrentEarthquakeProperty property.
    When NSXMLParser reports that it found characters in the parser:foundCharacters: delegate method, those characters are 
    appended to the contentOfCurrentEarthquakeProperty mutable string. 
 
    When the parser finishes processing an element, it invokes the delegate method 
    parser:didEndElement:namespaceURI:qualifiedName:. At that point, the sample sets the value of the property in the current
    Earthquake object (the currentEarthquakeObject property) to the value of the contentOfCurrentEarthquakeProperty string.

*/

@interface BaseXMLReader : NSObject
{
@private
    NSMutableString *_contentOfCurrentProperty;
	id		_target;
	SEL		_addObject;
}

+ (BaseXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) NSMutableString *contentOfCurrentProperty;
@property (nonatomic, retain) id target;
@property (nonatomic) SEL addObject;

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@end
