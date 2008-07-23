//
//  MovieListController.h
//  Untitled
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieListController : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSMutableArray *_movies;
	int _movieCount;
@public
	BOOL refreshMovies;
}

- (void)reloadData;

@property (nonatomic, retain) NSMutableArray *movies;
@property (nonatomic) int movieCount;
@property (nonatomic) BOOL refreshMovies;

@end
