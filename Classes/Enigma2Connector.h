//
//  Enigma2Connector.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

/*!
 @brief Connector for Enigma2 based STBs.
 */
@interface Enigma2Connector : NSObject <RemoteConnector> {
@private
	NSURL *baseAddress; /*!< @brief Base URL of STB */
}

@end
