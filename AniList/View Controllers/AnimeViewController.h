//
//  AnimeViewController.h
//  AniList
//
//  Created by Corey Roberts on 4/16/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AniListSummaryViewController.h"
#import "AnimeUserInfoViewController.h"
#import "AniListUserInfoViewController.h"
#import "TagView.h"

@class Anime;

@interface AnimeViewController : AniListSummaryViewController<AniListUserInfoViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, TagViewDelegate>

@property (nonatomic, strong) Anime *anime;

@end
