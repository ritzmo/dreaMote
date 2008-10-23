//
//  ServiceXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 23.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"

@class Service;

@interface NeutrinoServiceXMLReader : BaseXMLReader
{
@private
	Service *_currentServiceObject;
}

+ (NeutrinoServiceXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) Service *currentServiceObject;

@end
