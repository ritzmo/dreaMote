//
//  MovieSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IntelligentSplitViewController/IntelligentSplitViewController.h"
#import "LocationListController.h"
#import "MovieListController.h"
#import "MovieViewController.h"

@interface MovieSplitViewController : IntelligentSplitViewController {
@private
	LocationListController *_locationListController;
	MovieListController *_movieListController;
	MovieViewController *_movieViewController;
}

@end
