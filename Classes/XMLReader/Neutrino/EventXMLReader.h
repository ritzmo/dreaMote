//
//  EventXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "EventSourceDelegate.h"

/*!
 @brief Neutrino Event XML Reader.
 */
@interface NeutrinoEventXMLReader : BaseXMLReader
{
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return NeutrinoEventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate;

@end
