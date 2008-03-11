//
//  Enigma2Connector.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Enigma2Connector.h"

#import "Service.h"
#import "Timer.h"
#import "Event.h"
#import "Volume.h"

#ifdef STREAMING_PARSE
#import "XMLReaderSAX.h"
#else
#import "XMLDocument.h"
#import "XMLElement.h"
#endif

@implementation Enigma2Connector

@synthesize baseAddress;

- (id)initWithAddress:(NSString *) address
{
	baseAddress = [address copy];
	return self;
}

+ (id <RemoteConnector>*)createClassWithAddress:(NSString *) address
{
	return (id <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress: address];
}

- (BOOL)zapTo:(Service *) service
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/zap?sRef=%@", self.baseAddress, [service getServiceReference]];
	
	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
	
	// Compare to expected result
	return [myString isEqualToString: @"	<rootElement></rootElement>"];
}

#ifdef STREAMING_PARSE
- (NSArray *)fetchXmlDocument:(NSString *) myURI :(NSString *) myClass :(NSString *) myElement
{
	NSError *parseError = nil;

    NSDictionary *modelDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: myClass, myElement, nil];
    
    XMLReaderSAX *streamingParser = [[XMLReaderSAX alloc] init];
    [streamingParser setModelObjectDictionary: modelDictionary];
    [modelDictionary release];
    [streamingParser parseXMLFileAtURL: [NSURL URLWithString: myURI] parseError: &parseError];

    NSMutableArray *allElements = [NSMutableArray arrayWithArray: streamingParser.parsedModelObjects];

    // The parser creates the array of model objects, but it doesn't know when to dispose of it.
    // At this point we've taken the results and stored them elsewhere, so we can
    // tell the parser to release the model objects and avoid leaking them.
    [streamingParser releaseModelObjects];
    
    [streamingParser release];
	
	return allElements;
}
#endif

- (NSArray *)fetchServices
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/getservices?sRef=%@", self.baseAddress, @"1:7:1:0:0:0:0:0:0:0:FROM%20BOUQUET%20%22userbouquet.favourites.tv%22%20ORDER%20BY%20bouquet"];

    #ifdef STREAMING_PARSE
    
	return [self fetchXmlDocument: myURI :@"Service" :@"e2service"];

    #else

	NSError *parseError = nil;
	NSMutableArray *allServices = [NSMutableArray array];
    
    XMLDocument *document = [XMLDocument documentWithContentsOfURL: [NSURL URLWithString: myURI] error: &parseError];

	if (!document && !parseError) {
		// If document is nil and parseError is nil, the XML document from the web server was not available.
		// (If parseError is non-nil, the XML document was downloaded but parsing it failed).
		// This can happen if the network connection is broken.

		// XXX: we might want to signal our failure (eg by adding a "known false service")
		return allServices;
	}
    
	NSArray *itemElements = [document.rootElement descendantsNamed: @"e2service"];
	for (XMLElement *itemElement in itemElements) {
	
		/*
			Example:
            <?xml version="1.0" encoding="UTF-8"?>
            <e2servicelist>
               <e2service>
                   <e2servicereference>1:0:1:335:9DD0:7E:820000:0:0:0:</e2servicereference>
                   <e2servicename>M6 Suisse</e2servicename>
               </e2service>   
            </e2servicelist>
		*/

		Service *service = [[Service alloc] init];
        [allServices addObject:service];

		XMLElement *servicename = [itemElement firstChildNamed: @"e2servicename"];
		if (servicename) {
			NSString *servicenameContent = [servicename stringValue];
			if (servicenameContent && [servicenameContent length]) {
				service.sname = servicenameContent;
			}
		}
		
		XMLElement *serviceref = [itemElement firstChildNamed: @"e2servicereference"];
		if (serviceref) {
			NSString *servicerefContent = [serviceref stringValue];
			if (servicerefContent && [servicerefContent length]) {
				service.sref = servicerefContent;
			}
		}
	}

    return allServices;
	
	#endif
}

- (NSArray *)fetchEPG: (Service *) service
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/epgservice?sRef=%@", self.baseAddress, [service getServiceReference]];
	

    #ifdef STREAMING_PARSE

    return [self fetchXmlDocument: myURI :@"Event" :@"e2event"];
    
    #else
	
	NSError *parseError = nil;
	NSMutableArray *allEvents = [NSMutableArray array];

    XMLDocument *document = [XMLDocument documentWithContentsOfURL: [NSURL URLWithString: myURI] error: &parseError];

	if (!document && !parseError) {
		// If document is nil and parseError is nil, the XML document from the web server was not available.
		// (If parseError is non-nil, the XML document was downloaded but parsing it failed).
		// This can happen if the network connection is broken.

		// XXX: we might want to signal our failure (eg by adding a "known false event")
		return allEvents;
	}
    
	NSArray *itemElements = [document.rootElement descendantsNamed: @"e2event"];
	for (XMLElement *itemElement in itemElements) {
	
		/*
			Example:
            <?xml version="1.0" encoding="UTF-8"?>
			<e2eventlist>
				<e2event>
					<e2eventid>40710</e2eventid>
					<e2eventstart>1205037000</e2eventstart>
					<e2eventduration>1500</e2eventduration>
					<e2eventtitle>Aktion Schulstreich</e2eventtitle>
					<e2eventdescription>1. Hauptschule Sonthofen - Motto: Wir nageln Deutsch und Mathe an die Wand</e2eventdescription>
					<e2eventdescriptionextended>In dieser ersten Folge kommt der Notruf aus dem Allgäu. Die Räume der Hauptschule in der Alpenstadt Sonthofen sind ziemlich farblos und erinnern mehr an ein Kloster, als an eine fröhliche Schule.</e2eventdescriptionextended>
					<e2eventservicereference>1:0:1:6DCA:44D:1:C00000:0:0:0:</e2eventservicereference>
					<e2eventservicename>Das Erste</e2eventservicename>
				</e2event>
			</e2eventlist>
		*/

		Event *event = [[Event alloc] init];
        [allEvents addObject:event];

		XMLElement *eit = [itemElement firstChildNamed: @"e2eventid"];
		if (eit) {
			NSString *eitContent = [eit stringValue];
			if (eitContent && [eitContent length]) {
				event.eit = eitContent;
			}
		}
		
		XMLElement *begin = [itemElement firstChildNamed: @"e2eventstart"];
		if (begin) {
			NSString *beginContent = [begin stringValue];
			if (beginContent && [beginContent length]) {
				event.begin = beginContent;
			}
		}
		
		XMLElement *duration = [itemElement firstChildNamed: @"e2eventduration"];
		if (duration) {
			NSString *durationContent = [duration stringValue];
			if (durationContent && [durationContent length]) {
				event.duration = durationContent;
			}
		}
		
		XMLElement *title = [itemElement firstChildNamed: @"e2eventtitle"];
		if (title) {
			NSString *titleContent = [title stringValue];
			if (titleContent && [titleContent length]) {
				event.title = titleContent;
			}
		}
		
		XMLElement *description = [itemElement firstChildNamed: @"e2eventdescription"];
		if (description) {
			NSString *descriptionContent = [description stringValue];
			if (descriptionContent && [descriptionContent length]) {
				event.sdescription = descriptionContent;
			}
		}
		
		XMLElement *extended = [itemElement firstChildNamed: @"e2eventdescriptionextended"];
		if (extended) {
			NSString *extendedContent = [extended stringValue];
			if (extendedContent && [extendedContent length]) {
				event.edescription = extendedContent;
			}
		}
	}

	// XXX: we could also just change a member of the service (though there is none yet)

	return allEvents;
	
	#endif
}

- (NSArray *)fetchTimers
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/timerlist", self.baseAddress];

    #ifdef STREAMING_PARSE
	
	return [self fetchXmlDocument: myURI :@"Timer" :@"e2timer"];
    
    #else
    
	NSError *parseError = nil;
	NSMutableArray *allTimers = [NSMutableArray array];

    XMLDocument *document = [XMLDocument documentWithContentsOfURL: [NSURL URLWithString: myURI] error: &parseError];

	if (!document && !parseError) {
		// If document is nil and parseError is nil, the XML document from the web server was not available.
		// (If parseError is non-nil, the XML document was downloaded but parsing it failed).
		// This can happen if the network connection is broken.

		// XXX: we might want to signal our failure (eg by adding a "known false event")
		return allTimers;
	}
    
	NSArray *itemElements = [document.rootElement descendantsNamed: @"e2timer"];
	for (XMLElement *itemElement in itemElements) {
	
		/*
			Example:
            <?xml version="1.0" encoding="UTF-8"?>
            <e2timerlist>
            	<e2timer>
            		<e2servicereference>1:0:1:445C:453:1:C00000:0:0:0:</e2servicereference>
            		<e2servicename>SAT.1</e2servicename>
            		<e2eit>48286</e2eit>
            		<e2name>Numb3rs - Die Logik des Verbrechens</e2name>
            		<e2description>Numb3rs - Die Logik des Verbrechens</e2description>
            		<e2descriptionextended>N/A</e2descriptionextended>
            		<e2disabled>0</e2disabled>
            		<e2timebegin>1205093400</e2timebegin>
            		<e2timeend>1205097600</e2timeend>
            		<e2duration>4200</e2duration>
            		<e2startprepare>1205093380</e2startprepare>
            		<e2justplay>0</e2justplay>
            		<e2afterevent>0</e2afterevent>
            		<e2logentries></e2logentries>
            		<e2filename></e2filename>
            		<e2backoff>0</e2backoff>
            		<e2nextactivation></e2nextactivation>
            		<e2firsttryprepare>True</e2firsttryprepare>
            		<e2state>0</e2state>
            		<e2repeated>0</e2repeated>
            		<e2dontsave>0</e2dontsave>
            		<e2cancled>False</e2cancled>
            		<e2color>000000</e2color>
            		<e2toggledisabled>1</e2toggledisabled>
            		<e2toggledisabledimg>off</e2toggledisabledimg>
            	</e2timer>
            </e2timerlist>
		*/

		Timer *timer = [[Timer alloc] init];
        [allTimers addObject:timer];

		// XXX: implement

		XMLElement *title = [itemElement firstChildNamed: @"e2name"];
		if (title) {
			NSString *titleContent = [title stringValue];
			if (titleContent && [titleContent length]) {
				timer.title = titleContent;
			}
		}
		
		/*XMLElement * = [itemElement firstChildNamed: @""];
		if () {
			NSString *Content = [ stringValue];
			if (Content && [Content length]) {
				timer. = Content;
			}
		}*/
	}

	return allTimers;
	
	#endif
}

- (void)sendPowerstate: (int) newState
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/powerstate?newstate=%d", self.baseAddress, newState];
	
	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

- (void)shutdown
{
	[self sendPowerstate: 1];
}

- (void)standby
{
	// XXX: we send remote control command 116 here as we want to toggle standby

	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/remotecontrol?command=116", self.baseAddress];
	
	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

- (void)reboot
{
	[self sendPowerstate: 2];
}

- (void)restart
{
	[self sendPowerstate: 3];
}

- (Volume *)getVolume
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol", self.baseAddress];

    #ifdef STREAMING_PARSE
	
	NSArray *allVolumes = [self fetchXmlDocument: myURI :@"Volume" :@"e2volume"];
    
    #else
    
	NSError *parseError = nil;
	NSMutableArray *allVolumes = [NSMutableArray array];

    XMLDocument *document = [XMLDocument documentWithContentsOfURL: [NSURL URLWithString: myURI] error: &parseError];

	if (!document && !parseError) {
		// If document is nil and parseError is nil, the XML document from the web server was not available.
		// (If parseError is non-nil, the XML document was downloaded but parsing it failed).
		// This can happen if the network connection is broken.

		// XXX: we might want to signal our failure (eg by adding known false values)
		return [[Volume alloc] init];
	}
    
	NSArray *itemElements = [document.rootElement descendantsNamed: @"e2volume"];
	for (XMLElement *itemElement in itemElements) {
	
		/*
			Example:
            <?xml version="1.0" encoding="UTF-8"?>
            <e2volume>
               <e2result>True</e2result>
               <e2resulttext>state</e2resulttext>
               <e2current>5</e2current>
               <e2ismuted>False</e2ismuted>	
            </e2volume>
		*/

		Volume *volume = [[Volume alloc] init];
        [allVolumes addObject:volume];

		// XXX: implement

		XMLElement *ismuted = [itemElement firstChildNamed: @"e2ismuted"];
		if (ismuted) {
			NSString *ismutedContent = [ismuted stringValue];
			if (ismutedContent && [ismutedContent length]) {
				volume.ismuted = ismutedContent;
			}
		}
		
		/*XMLElement * = [itemElement firstChildNamed: @""];
		if () {
			NSString *Content = [ stringValue];
			if (Content && [Content length]) {
				volume. = Content;
			}
		}*/
	}
	
	#endif

	Volume *returnVolume = [allVolumes objectAtIndex: 0];
	//[allVolumes release];

	return returnVolume;
}

- (BOOL)toggleMuted
{
	BOOL returnValue = NO;

	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol?set=mute", self.baseAddress];

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
	
	NSRange myRange = [myString rangeOfString: @"<e2ismuted>True</e2ismuted>"];
	if(myRange.length)
		returnValue = YES;
	
	return returnValue;
}

- (void)setVolume:(int) newVolume
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol?set=set%d", self.baseAddress, newVolume];
	
	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

@end
