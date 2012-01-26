//
//  NeutrinoConnector.h
//  dreaMote
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Connector/RemoteConnector.h>

/*!
 @brief Connector for Neutrino based STBs.
 */
@interface NeutrinoConnector : NSObject <RemoteConnector> {
@private
	NSURL *_baseAddress; /*!< @brief Base URL of STB */
}

@end
