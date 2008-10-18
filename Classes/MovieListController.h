//
//  MovieListController.h
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FuzzyDateFormatter;
@class MovieViewController;

@interface MovieListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_movies;
	FuzzyDateFormatter *dateFormatter;

	MovieViewController *movieViewController;
	BOOL refreshMovies;
}

@end
