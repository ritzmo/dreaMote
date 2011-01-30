//
//  BouquetSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MGSplitViewController/MGSplitViewController.h"
#import "BouquetListController.h"
#import "ServiceListController.h"

@interface BouquetSplitViewController : MGSplitViewController {
@private
	BouquetListController *_bouquetListController;
	ServiceListController *_serviceListController;
}

@end
