//
//  SimulatedTimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright 2012 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/TimerSourceDelegate.h>

/*!
 @brief Enigma2 Simulated Timer XML Reader.
 */
@interface Enigma2SimulatedTimerXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2SimulatedTimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<TimerSourceDelegate> *)delegate;

@end
