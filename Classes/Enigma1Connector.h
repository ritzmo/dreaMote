//
//  Enigma1Connector.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

@interface Enigma1Connector : NSObject <RemoteConnector> {
@private
	NSString *baseAddress;
}

@property (nonatomic, retain) NSString *baseAddress;

@end
