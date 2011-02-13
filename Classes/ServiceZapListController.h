//
//  ServiceZapListController.h
//  dreaMote
//
//  Created by Moritz Venn on 13.02.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Zap actions.

 @note Keep in sync with the row indices of the fully populated list.
 */
typedef enum
{
	zapActionRemote = 0,
	zapActionOPlayer = 1,
	zapActionOPlayerLite = 2,
} zapAction;

@protocol ServiceZapListDelegate;

/*!
 @brief Table showing actions you can execute for a specific service.

 @note This table is used only on the iPad to make the UI more appealing, as a
 UIActionSheet (which is used on the iPhone) disturbs the ui flow too much while a popover
 appears more like a "side-action". To keep code duplication to a minimum, the resulting
 actions are not handled in this class but in the event list where the iPhone-equivalent resides.
 */
@interface ServiceZapListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSObject<ServiceZapListDelegate> *_zapDelegate; /*!< @brief Zap delegate. */
}

@property (nonatomic, retain) NSObject<ServiceZapListDelegate> *zapDelegate;

@end



/*!
 @brief Defines callbacks for this view.
*/
@protocol ServiceZapListDelegate
/*!
 @brief Selection was made.

 @param zapListController controller the selection was done in
 @param selectedAction action the user selected
 */
- (void)serviceZapListController:(ServiceZapListController *)zapListController selectedAction:(zapAction)selectedAction;
@end