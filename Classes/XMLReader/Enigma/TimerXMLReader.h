//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/TimerSourceDelegate.h>

/*!
 @brief Enigma Timer XML Reader.
 */
@interface EnigmaTimerXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaTimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<TimerSourceDelegate> *)delegate;

@end
