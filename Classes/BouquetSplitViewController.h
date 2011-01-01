//
//  BouquetSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BaseSplitViewController.h"
#import "BouquetListController.h"
#import "ServiceListController.h"

@interface BouquetSplitViewController : BaseSplitViewController {
@private
	BouquetListController *_bouquetListController;
	ServiceListController *_serviceListController;
}

@end
