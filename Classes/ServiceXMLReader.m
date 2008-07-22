// Header

#import "ServiceXMLReader.h"

static NSUInteger parsedServicesCounter;

@implementation ServiceXMLReader

@synthesize currentServiceObject = _currentServiceObject;

// Services are 'lightweight'
#define MAX_SERVICES 2048

+ (ServiceXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	ServiceXMLReader *xmlReader = [[ServiceXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedServicesCounter = 0;
}

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
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName)
	{
		elementName = qName;
	}

	// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
	// Otherwise the application runs very slowly on the device.
	if (parsedServicesCounter >= MAX_SERVICES)
	{
		[parser abortParsing];
	}
	
	if ([elementName isEqualToString:@"e2service"])
	{
		parsedServicesCounter++;

		// An e2service in the xml represents a service, so create an instance of it.
		self.currentServiceObject = [[Service alloc] init];
		[self.target performSelector:self.addObject withObject:self.currentServiceObject];

		return;
	}
		
	if ([elementName isEqualToString:@"e2servicereference"]) {
		// Create a mutable string to hold the contents of the 'e2servicereference' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else if ([elementName isEqualToString:@"e2servicename"]) {
		// Create a mutable string to hold the contents of the 'e2servicename' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else {
		// The element isn't one that we care about, so set the property that holds the 
		// character content of the current element to nil. That way, in the parser:foundCharacters:
		// callback, the string that the parser reports will be ignored.
		self.contentOfCurrentProperty = nil;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{	 
	if (qName) {
		elementName = qName;
	}

	if ([elementName isEqualToString:@"e2servicereference"]) {
		[[self currentServiceObject] setSref: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2servicename"]) {
		[[self currentServiceObject] setSname: [self contentOfCurrentProperty]];
	}
	self.contentOfCurrentProperty = nil;
}

@end
