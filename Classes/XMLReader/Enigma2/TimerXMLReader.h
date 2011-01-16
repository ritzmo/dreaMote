//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "TimerSourceDelegate.h"

/*!
 @brief Enigma2 Timer XML Reader.
 */
@interface Enigma2TimerXMLReader : SaxXmlReader
{
@private
	NSObject<TimerSourceDelegate> *_delegate; /*!< @brief Delegate. */
	NSObject<TimerProtocol> *currentTimer; /*!< @brief Current Timer. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2TimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<TimerSourceDelegate> *)delegate;

@end
