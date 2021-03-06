//
//  AniListViewController.h
//  AniList
//
//  Created by Corey Roberts on 4/15/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "BaseViewController.h"
#import "AniListTableView.h"
#import "AniListNavigationController.h"
#import "ImageManager.h"
#import "AniListTableHeaderView.h"

@interface AniListViewController : BaseViewController<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSArray *sectionHeaders;
@property (nonatomic, strong) NSMutableArray *sectionHeaderViews;
@property (nonatomic, weak) IBOutlet UIView *maskView;
@property (nonatomic, weak) IBOutlet AniListTableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *menuButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, strong) NSIndexPath *editedIndexPath;
@property (nonatomic, assign) int requestAttempts;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;
@property (nonatomic, assign) BOOL loadSectionHeaders;
@property (nonatomic, assign) BOOL displayWatching;
@property (nonatomic, assign) BOOL displayCompleted;
@property (nonatomic, assign) BOOL displayOnHold;
@property (nonatomic, assign) BOOL displayDropped;
@property (nonatomic, assign) BOOL displayPlanToWatch;

- (void)fetchData;
- (NSString *)entityName;
- (NSArray *)sortDescriptors;
- (NSString *)sectionKeyPathName;
- (void)configureCell:(UITableViewCell *)cell withObject:(NSManagedObject *)object;
- (NSManagedObject *)objectForIndexPath:(NSIndexPath *)indexPath;

- (void)didSwipe:(UIGestureRecognizer *)gestureRecognizer;
- (void)didCancel:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateMapping;

@end
