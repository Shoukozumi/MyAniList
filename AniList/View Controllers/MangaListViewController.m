//
//  MangaListViewController.m
//  AniList
//
//  Created by Corey Roberts on 4/16/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "MangaListViewController.h"
#import "MangaViewController.h"
#import "MangaService.h"
#import "MangaCell.h"
#import "Manga.h"
#import "MALHTTPClient.h"
#import "AniListAppDelegate.h"
#import "MangaUserInfoEditViewController.h"
#import "AniListTableHeaderView.h"

static BOOL alreadyFetched = NO;

@interface MangaListViewController ()
@property (nonatomic, strong) Manga *editedManga;
@end

@implementation MangaListViewController

- (id)init {
    self = [super init];
    if(self) {
        self.title = @"Manga";
        self.sectionHeaders = @[@"Reading", @"Completed", @"On Hold",
                                @"Dropped", @"Plan To Read"];
        
        [self createHeaders];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchData) name:kUserLoggedIn object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteManga) name:kDeleteManga object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [NSFetchedResultsController deleteCacheWithName:[self entityName]];
    ALLog(@"MangaList deallocating.");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.errorLabel.text = @"Looks like you don't have any manga on your list! Why not do a search for some?";
    
    if(!alreadyFetched) {
        if(self.fetchedResultsController.fetchedObjects.count > 0) {
            alreadyFetched = YES;
        }
    }
    else {
        // Can happen if a user clears his/her cache.
        if(self.fetchedResultsController.fetchedObjects.count == 0) {
            alreadyFetched = NO;
        }
    }
    
    [self fetchData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[AnalyticsManager sharedInstance] trackView:kMangaListScreen];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)entityName {
    return @"Manga";
}

- (NSArray *)sortDescriptors {
    NSSortDescriptor *statusDescriptor = [[NSSortDescriptor alloc] initWithKey:@"read_status" ascending:YES];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    return @[statusDescriptor, sortDescriptor];
}

- (NSPredicate *)predicate {
    return [NSPredicate predicateWithFormat:@"read_status < 7"];
}

-  (void)createHeaders {
    for(int i = 0; i < 5; i++) {
        NSString *count = @"";
        int sectionValue = 0;
        
        BOOL expanded = NO;
        
        switch (i) {
            case 0:
                expanded = self.displayWatching;
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusReading];
                break;
            case 1:
                expanded = self.displayCompleted;
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusCompleted];
                break;
            case 2:
                expanded = self.displayOnHold;
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusOnHold];
                break;
            case 3:
                expanded = self.displayDropped;
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusDropped];
                break;
            case 4:
                expanded = self.displayPlanToWatch;
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusPlanToRead];
                break;
            default:
                break;
        }
        
        count = [NSString stringWithFormat:@"%d", sectionValue];
        
        AniListTableHeaderView *headerView = [[AniListTableHeaderView alloc] initWithPrimaryText:self.sectionHeaders[i] andSecondaryText:count isExpanded:expanded];
        headerView.tag = i;
        
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] init];
        gestureRecognizer.numberOfTapsRequired = 1;
        [gestureRecognizer addTarget:headerView action:@selector(expand)];
        [gestureRecognizer addTarget:self action:@selector(expand:)];
        [headerView addGestureRecognizer:gestureRecognizer];
        
        [self.sectionHeaderViews addObject:headerView];
    }
}

- (void)fetchData {
    
    [UIView animateWithDuration:0.15f animations:^{
        self.tableView.tableFooterView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.tableView.tableFooterView = nil;
    }];
    
    if([UserProfile userIsLoggedIn]) {
       
        self.requestAttempts++;
        
        if(!alreadyFetched) {
            self.tableView.alpha = 1.0f;
            self.indicator.alpha = 1.0f;
        }
        
        [[MALHTTPClient sharedClient] getMangaListForUser:[[UserProfile profile] username]
                                             initialFetch:YES
                                                  success:^(NSURLRequest *operation, id response) {
                                                      [MangaService addMangaList:(NSDictionary *)response];
                                                      alreadyFetched = YES;
                                                      [super fetchData];
                                                  }
                                                  failure:^(NSURLRequest *operation, NSError *error) {
                                                      alreadyFetched = YES;
                                                      if(self.requestAttempts < MAX_ATTEMPTS) {
                                                          ALLog(@"Could not fetch, trying attempt %d of %d...", self.requestAttempts, MAX_ATTEMPTS);
                                                          
                                                          // Try again.
                                                          double delayInSeconds = 1.0;
                                                          dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                          dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                              [self fetchData];
                                                          });
                                                      }
                                                      else {
                                                          if(self.fetchedResultsController.fetchedObjects.count == 0) {
                                                              double delayInSeconds = 0.25f;
                                                              dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                              dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                                  self.tableView.tableFooterView = [UIView tableFooterWithError];
                                                                  self.tableView.tableFooterView.alpha = 0.0f;
                                                                  [UIView animateWithDuration:0.15 animations:^{
                                                                      self.tableView.tableFooterView.alpha = 1.0f;
                                                                  }];
                                                              });
                                                          }
                                                          
                                                          [super fetchData];
                                                      }
                                                  }];
    }
}


- (void)saveManga:(Manga *)manga {
    if(manga) {
        
        [[AnalyticsManager sharedInstance] trackEvent:kMangaQuickEditUsed forCategory:EventCategoryAction withMetadata:[manga.manga_id stringValue]];
        
        [[MALHTTPClient sharedClient] updateDetailsForMangaWithID:manga.manga_id success:^(id operation, id response) {
            ALLog(@"Updated '%@'.", manga.title);
        } failure:^(id operation, NSError *error) {
            ALLog(@"Failed to update '%@'.", manga.title);
        }];
    }
    
    self.editedIndexPath = nil;
    self.editedManga = nil;
}

- (void)deleteManga {
    if(self.editedManga) {
        self.editedManga.read_status = @(MangaReadStatusNotReading);
        
        if(self.editedManga.manga_id) {
            NSNumber *ID = self.editedManga.manga_id;
            [[MALHTTPClient sharedClient] deleteMangaWithID:ID success:^(id operation, id response) {
                ALLog(@"Manga successfully deleted.");
            } failure:^(id operation, NSError *error) {
                ALLog(@"Manga failed to delete.");
            }];
        }
    }
    
    self.editedIndexPath = nil;
    self.editedManga = nil;
}


#pragma mark - Gesture Management Methods

- (void)didSwipe:(UIGestureRecognizer *)gestureRecognizer {
    [super didSwipe:gestureRecognizer];
    
    if (([gestureRecognizer isMemberOfClass:[UISwipeGestureRecognizer class]] && gestureRecognizer.state == UIGestureRecognizerStateEnded) ||
        ([gestureRecognizer isMemberOfClass:[UILongPressGestureRecognizer class]] && gestureRecognizer.state == UIGestureRecognizerStateBegan)) {
        
        CGPoint swipeLocation = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
        AniListCell *swipedCell = (AniListCell *)[self.tableView cellForRowAtIndexPath:swipedIndexPath];
        
        self.editedManga = (Manga *)[self objectForIndexPath:swipedIndexPath];
        
        [swipedCell showEditScreenForManga:self.editedManga];
    }
}

- (void)didCancel:(UIGestureRecognizer *)gestureRecognizer {
    [super didCancel:gestureRecognizer];
    
    if((([self.editedManga.current_chapter intValue] > 0 || [self.editedManga.current_volume intValue] > 0) && [self.editedManga.read_status intValue] != MangaReadStatusReading) &&
       (([self.editedManga.current_chapter intValue] > 0 || [self.editedManga.current_volume intValue] > 0) && [self.editedManga.read_status intValue] != MangaReadStatusCompleted)) {
        [self promptForBeginning:self.editedManga];
    }
    else {
        [self saveManga:self.editedManga];
    }
}

#pragma mark - Action Sheet Methods

- (void)promptForBeginning:(Manga *)manga {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Do you want to mark '%@' as reading?", manga.title]
                                                             delegate:self
                                                    cancelButtonTitle:@"No"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Yes", nil];
    actionSheet.tag = ActionSheetPromptBeginning;
    
    [actionSheet showInView:self.view];
}

- (void)promptForFinishing:(Manga *)manga {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Do you want to mark '%@' as completed?", manga.title]
                                                             delegate:self
                                                    cancelButtonTitle:@"No"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Yes", nil];
    actionSheet.tag = ActionSheetPromptFinishing;
    
    [actionSheet showInView:self.view];
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.sectionHeaderViews[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [MangaCell cellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    static NSString *CellIdentifier = @"Cell";
    
    MangaCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MangaCell" owner:self options:nil];
        cell = (MangaCell *)nib[0];
    }
    
    Manga *manga = (Manga *)[self objectForIndexPath:indexPath];
    
    [self configureCell:cell withObject:manga];
    
    if(self.editedIndexPath && self.editedIndexPath.section == indexPath.section && self.editedIndexPath.row == indexPath.row) {
        [cell showEditScreenForManga:manga];
        
        UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didCancel:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [cell addGestureRecognizer:tapGestureRecognizer];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        
        self.editedManga = (Manga *)[self objectForIndexPath:indexPath];
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Do you really want to delete '%@'?", self.editedManga.title]
                                                                 delegate:self
                                                        cancelButtonTitle:@"No"
                                                   destructiveButtonTitle:@"Yes"
                                                        otherButtonTitles:nil];
        actionSheet.tag = ActionSheetPromptDeletion;
        
        [actionSheet showInView:self.view];
    }
}

static int map[5] = {-1, -1, -1, -1, -1};
static BOOL initialUpdate = NO;

- (void)updateMapping {
    
    for(int i = 0; i < 5; i++) {
        map[i] = -1;
    }
    
    for(int i = 0; i < self.fetchedResultsController.sections.count; i++) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][i];
        map[i] = [sectionInfo.name intValue];
    }
    
    ALVLog(@"map: (%d, %d, %d, %d, %d)", map[0], map[1], map[2], map[3], map[4]);
}

- (void)updateHeaders {
    for(int i = 0; i < self.sectionHeaderViews.count; i++) {
        AniListTableHeaderView *view = self.sectionHeaderViews[i];
        
        int sectionValue = 0;
        
        switch (i) {
            case 0:
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusReading];
                break;
            case 1:
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusCompleted];
                break;
            case 2:
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusOnHold];
                break;
            case 3:
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusDropped];
                break;
            case 4:
                sectionValue = [MangaService numberOfMangaForReadStatus:MangaReadStatusPlanToRead];
                break;
            default:
                break;
        }
        
        view.secondaryText = [NSString stringWithFormat:@"%d", sectionValue];
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    
    Manga *manga = (Manga *)anObject;
    
    if(!initialUpdate) {
        initialUpdate = YES;
        [self updateMapping];
    }
    
    ALVLog(@"%@ - (%d, %d) to (%d, %d)", manga.title, indexPath.section, indexPath.row, newIndexPath.section, newIndexPath.row);
    
    ALVLog(@"Updating indexPath section from %d to %d.", indexPath.section, map[indexPath.section]);
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:map[indexPath.section]];
    
    if(newIndexPath) {
        [self updateMapping];
        ALVLog(@"Updating newIndexPath section from %d to %d.", newIndexPath.section, map[newIndexPath.section]);
        newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:map[newIndexPath.section]];
    }

    
    [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            break;
            
        case NSFetchedResultsChangeDelete:
            break;
            
        case NSFetchedResultsChangeUpdate:
            if(self.editedIndexPath) {
                if((([self.editedManga.current_chapter intValue] == [self.editedManga.total_chapters intValue]) ||
                    ([self.editedManga.current_volume intValue] == [self.editedManga.total_volumes intValue])) &&
                     [self.editedManga.read_status intValue] != MangaReadStatusCompleted &&
                    ([self.editedManga.total_chapters intValue] != 0 || [self.editedManga.total_volumes intValue] != 0) ) {
                    
                    [self promptForFinishing:self.editedManga];
                }
            }
            break;
            
        case NSFetchedResultsChangeMove:
            break;
    }
    
    [self updateMapping];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];
    
    [self updateHeaders];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Manga *manga = (Manga *)[self objectForIndexPath:indexPath];
    
    AniListNavigationController *navigationController = (AniListNavigationController *)self.navigationController;
    
    MangaViewController *mvc = [[MangaViewController alloc] init];
    mvc.manga = manga;
    mvc.currentYBackgroundPosition = navigationController.imageView.frame.origin.y;
    
    [self.navigationController pushViewController:mvc animated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![self.tableView isEditing];
}

- (void)configureCell:(UITableViewCell *)cell withObject:(NSManagedObject *)object {
    Manga *manga = (Manga *)object;
    MangaCell *mangaCell = (MangaCell *)cell;
    [mangaCell setDetailsForManga:manga];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [super scrollViewDidScroll:scrollView];
    [self didCancel:nil];
}

#pragma mark - UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case ActionSheetPromptBeginning:
            if(buttonIndex == 0) {
                self.editedManga.read_status = @(MangaReadStatusReading);
                if(!self.editedManga.user_date_start)
                    self.editedManga.user_date_start = [NSDate date];
                [self.editedManga.managedObjectContext save:nil];
                
                [self saveManga:self.editedManga];
            }
            break;
        case ActionSheetPromptFinishing:
            if(buttonIndex == 0) {
                self.editedManga.read_status = @(MangaReadStatusCompleted);
                self.editedManga.current_chapter = self.editedManga.total_chapters;
                self.editedManga.current_volume = self.editedManga.total_volumes;

                if(!self.editedManga.user_date_finish)
                    self.editedManga.user_date_finish = [NSDate date];
                MangaUserInfoEditViewController *vc = [[MangaUserInfoEditViewController alloc] init];
                vc.manga = self.editedManga;
                [self.navigationController pushViewController:vc animated:YES];
                self.editedIndexPath = nil;
                self.editedManga = nil;
            }
            break;
        case ActionSheetPromptDeletion:
            if(buttonIndex == actionSheet.destructiveButtonIndex) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteManga object:nil];
            }
            break;
        default:
            break;
    }
}

@end
