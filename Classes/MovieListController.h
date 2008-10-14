//
//  MovieListController.h
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FuzzyDateFormatter.h"

@class MovieViewController;

@interface MovieListController : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSMutableArray *_movies;
	FuzzyDateFormatter *dateFormatter;

	MovieViewController *movieViewController;
@public
	BOOL refreshMovies;
}

- (void)reloadData;

@property (nonatomic, retain) NSMutableArray *movies;
@property (nonatomic) BOOL refreshMovies;
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
