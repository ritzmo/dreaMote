//
//  SignalXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "SignalSourceDelegate.h"

/*!
 @brief Enigma2 Signal XML Reader.
 */
@interface Enigma2SignalXMLReader : BaseXMLReader
{
@private
	NSObject<SignalSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2SignalXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate;

@end
