//
//  ServiceXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Service.h"
#import "BaseXMLReader.h"

@interface ServiceXMLReader : BaseXMLReader
{
@private
	Service *_currentServiceObject;
}

+ (ServiceXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) Service *currentServiceObject;

//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@end
