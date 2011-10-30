//
//  AboutViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/AboutProtocol.h"
#import "AboutSourceDelegate.h"
#import "ReloadableListController.h"

// Forward declarations...
@class BaseXMLReader;

/*!
 @brief About Receiver.
 
 Displays the software / image version, hdd and tuner info.
 */
@interface AboutViewController : ReloadableListController <UITableViewDelegate,
													UITableViewDataSource,
													AboutSourceDelegate>
{
@private
	NSObject<AboutProtocol> *_about; /*!< @brief Receiver information. */
	BaseXMLReader *_xmlReader; /*!< @brief About XML Document. */
}

@end
