//
//  AniListSummaryViewController.h
//  AniList
//
//  Created by Corey Roberts on 6/3/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "BaseViewController.h"
#import "AniListRelatedTableView.h"
#import "AniListMiniCell.h"

@class SynopsisView;

@interface AniListSummaryViewController : BaseViewController<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UILabel *synopsisLabel;
@property (nonatomic, strong) SynopsisView *synopsisView;
@property (nonatomic, strong) NSArray *relatedData;
@property (nonatomic, strong) AniListRelatedTableView *relatedTableView;
@property (nonatomic, strong) UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UIView *maskView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) float currentYBackgroundPosition;

- (void)adjustTitle;

@end
