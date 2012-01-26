//
//  BouquetSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AdSupportedSplitViewController.h"
#import "BouquetListController.h"
#import "ServiceListController.h"

@interface BouquetSplitViewController : AdSupportedSplitViewController {
@private
	BouquetListController *_bouquetListController;
	ServiceListController *_serviceListController;
}

@end
