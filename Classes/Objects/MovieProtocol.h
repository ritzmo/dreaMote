//
//  MovieProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Interface of a Movie.
 */
@protocol MovieProtocol

/*!
 @brief Service Reference
 */
@property (nonatomic, strong) NSString *sref;

/*!
 @brief Service Name
 */
@property (nonatomic, strong) NSString *sname;

/*!
 @brief Begin.
 */
@property (nonatomic, strong) NSDate *time;

/*!
 @brief Cache for Begin Textual representation.
 */
@property (nonatomic, strong) NSString *timeString;

/*!
 @brief Title.
 */
@property (nonatomic, strong) NSString *title;

/*!
 @brief Short Description.
 */
@property (nonatomic, strong) NSString *sdescription;

/*!
 @brief Extended Description.
 */
@property (nonatomic, strong) NSString *edescription;

/*!
 @brief Length.
 */
@property (nonatomic, strong) NSNumber *length;

/*!
 @brief Filesize.
 */
@property (nonatomic, strong) NSNumber *size;

/*!
 @brief Filename.
 */
@property (nonatomic, strong) NSString *filename;

/*!
 @brief Tags.
 */
@property (nonatomic, strong) NSArray *tags;

/*!
 @brief Valid or Fake Event.
 */
@property (nonatomic, readonly, getter = isValid) BOOL valid;



/*!
 @brief Set begin from Unix Timestamp contained in String.

 @param newTime Unix Timestamp as String.
 */
- (void)setTimeFromString: (NSString *)newTime;

/*!
 @brief Set Tag list from String representation.

 @param newTags String representation of Tags.
 */
- (void)setTagsFromString: (NSString *)newTags;

/*!
 @brief Compare to another movie by time.

 @param otherMovie Movie to compare to.
 @return NSComparisonResult
 */
- (NSComparisonResult)timeCompare:(NSObject<MovieProtocol> *)otherMovie;

/*!
 @brief Compare to another movie by title.

 @param otherMovie Movie to compare to.
 @return NSComparisonResult
 */
- (NSComparisonResult)titleCompare:(NSObject<MovieProtocol> *)otherMovie;

@end
