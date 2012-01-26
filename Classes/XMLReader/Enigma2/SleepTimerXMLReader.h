//
//  SleepTimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "SleepTimerSourceDelegate.h"

/*!
 @brief Enigma2 SleepTimer XML Reader.
 */
@interface Enigma2SleepTimerXMLReader : SaxXmlReader
{
@private
	SleepTimer *sleepTimer; /*!< @brief SleepTimer instance. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2SleepTimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<SleepTimerSourceDelegate> *)delegate;

@end
