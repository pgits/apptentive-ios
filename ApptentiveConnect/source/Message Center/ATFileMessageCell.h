//
//  ATFileMessageCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATMessageCenterCell.h"
#import "ATFileMessage.h"

@interface ATFileMessageCell : UITableViewCell <ATMessageCenterCell> {
	UILabel *dateLabel;
	UIImageView *userIcon;
	UIImageView *imageView;
	BOOL showDateLabel;
	ATFileMessage *fileMessage;
	UIImage *currentImage;
}
@property (retain, nonatomic) IBOutlet UILabel *dateLabel;
@property (retain, nonatomic) IBOutlet UIImageView *userIcon;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIView *imageContainer;
@property (nonatomic, assign, getter = shouldShowDateLabel) BOOL showDateLabel;

- (void)configureWithFileMessage:(ATFileMessage *)message;
@end
