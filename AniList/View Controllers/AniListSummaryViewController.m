//
//  AniListSummaryViewController.m
//  AniList
//
//  Created by Corey Roberts on 6/3/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AniListSummaryViewController.h"
#import "AniListNavigationController.h"
#import "MALHTTPClient.h"
#import "AnimeViewController.h"
#import "MangaViewController.h"

@interface AniListSummaryViewController ()

@end

@implementation AniListSummaryViewController

- (id)init {
    return [self initWithNibName:@"AniListSummaryViewController" bundle:[NSBundle mainBundle]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.titleLabel.alpha = 0.0f;
    self.view.backgroundColor = [UIColor clearColor];
    
    if([UIApplication isiOS7]) {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x + 10, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width - 20, self.titleLabel.frame.size.height);
    }
    
    self.relatedTableView = [[AniListRelatedTableView alloc] initWithFrame:CGRectMake(0, 400, 320, 100)];
    self.relatedTableView.delegate = self;
    self.relatedTableView.dataSource = self;
    self.relatedTableView.rowHeight = [AniListMiniCell cellHeight];
    self.relatedTableView.sectionHeaderHeight = 60;
    self.relatedTableView.sectionFooterHeight = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCellWithObject:) name:kRelatedAnimeDidUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCellWithObject:) name:kRelatedMangaDidUpdate object:nil];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.maskView.frame;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], (id)[[UIColor colorWithRed:1 green:0 blue:0 alpha:1] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.0, 0.075f);
    gradient.endPoint = CGPointMake(0.0f, 0.10f);
    
    self.maskView.layer.mask = gradient;
    
    self.view.frame = [UIScreen mainScreen].bounds;
}

- (void)viewWillAppear:(BOOL)animated {
//    AniListNavigationController *navigationController = (AniListNavigationController *)self.navigationController;
//    [UIView animateWithDuration:1.0f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
//                     animations:^{
//                         navigationController.imageView.frame = CGRectMake(navigationController.imageView.frame.origin.x, 0, navigationController.imageView.frame.size.width, navigationController.imageView.frame.size.height);
//                     }
//                     completion:nil];
    
    if([UIApplication isiOS7]) {
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.view.alpha = 1.0f;
                         }
                         completion:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
//    AniListNavigationController *navigationController = (AniListNavigationController *)self.navigationController;
//    [UIView animateWithDuration:1.0f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
//                     animations:^{
//                         navigationController.imageView.frame = CGRectMake(navigationController.imageView.frame.origin.x, self.currentYBackgroundPosition, navigationController.imageView.frame.size.width, navigationController.imageView.frame.size.height);
//                     }
//                     completion:nil];
    
    if([UIApplication isiOS7]) {
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.view.alpha = 0.0f;
                         }
                         completion:nil];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.relatedTableView.delegate = nil;
    self.scrollView.delegate = nil;
}

#pragma mark - UILabel Fix Method

- (void)adjustTitle {
    int maxDesiredFontSize = 19;
    int minFontSize = 10;
    CGFloat labelWidth = self.titleLabel.frame.size.width;
    CGFloat labelRequiredHeight = self.titleLabel.frame.size.height;
    
    /* This is where we define the ideal font that the Label wants to use.
     Use the font you want to use and the largest font size you want to use. */
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:maxDesiredFontSize];
    
    /* Time to calculate the needed font size.
     This for loop starts at the largest font size, and decreases by two point sizes (i=i-2)
     Until it either hits a size that will fit or hits the minimum size we want to allow (i > 10) */
    int i = 0;
    for(i = maxDesiredFontSize; i > minFontSize; i = i-2) {
        // Set the new font size.
        font = [font fontWithSize:i];
        // You can log the size you're trying: NSLog(@"Trying size: %u", i);
        
        /* This step is important: We make a constraint box
         using only the fixed WIDTH of the UILabel. The height will
         be checked later. */
        CGSize constraintSize = CGSizeMake(labelWidth, MAXFLOAT);
        
        // This step checks how tall the label would be with the desired font.
        CGSize labelSize = [self.titleLabel.text sizeWithFont:font
                                            constrainedToSize:constraintSize
                                                lineBreakMode:NSLineBreakByTruncatingTail];
        
        /* Here is where you use the height requirement!
         Set the value in the if statement to the height of your UILabel
         If the label fits into your required height, it will break the loop
         and use that font size. */
        if(labelSize.height <= labelRequiredHeight)
            break;
    }

    ALLog(@"Best size calculated: %u", i);
    
    // Set the UILabel's font to the newly adjusted font.
    self.titleLabel.font = font;
}

#pragma mark - Animation Methods

- (void)displayTitle {
    [UIView animateWithDuration:0.5f animations:^{
        self.titleLabel.alpha = 1.0f;
    }];
}

- (void)removeTitle {
    [UIView animateWithDuration:0.3f animations:^{
        self.titleLabel.alpha = 0.0f;
    }];
}

#pragma mark - Related Content View Methods

- (void)reloadCellWithObject:(NSNotification *)notification {
    NSManagedObject *object = notification.object;
    for(int i = 0; i < self.relatedData.count; i++) {
        NSDictionary *section = self.relatedData[i];
//        for(int j = 0; j < [[section allValues][0] count]; i++) {
//            NSManagedObject *obj = [section allValues][0][i];
//            if(obj == object) {
//                // We've found the object; now find it in the table view.
//                for(int k = 0; k < [self.relatedTableView numberOfRowsInSection:i]; k++) {
//                    AniListMiniCell *cell = (AniListMiniCell *)[self.relatedTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:k inSection:i]];
//                    if(([obj isMemberOfClass:[Anime class]] && [cell.title.text isEqualToString:((Anime *)obj).title]) ||
//                       ([obj isMemberOfClass:[Manga class]] && [cell.title.text isEqualToString:((Manga *)obj).title])) {
//                        [self.relatedTableView beginUpdates];
//                        [self.relatedTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:k inSection:i]] withRowAnimation:UITableViewRowAnimationFade];
//                        [self.relatedTableView endUpdates];
//                        break;
//                    }
//                }
//            }
//        }
        for(NSManagedObject *obj in [section allValues][0]) {
            if(obj == object) {
                [self.relatedTableView beginUpdates];
                [self.relatedTableView reloadSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
                [self.relatedTableView endUpdates];
            }
        }
    }
}

- (void)configureAnimeCell:(AniListMiniCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Anime *anime = [self.relatedData[indexPath.section] allValues][0][indexPath.row];
    
    cell.title.text = anime.title;
    [cell.title sizeToFit];
    
    cell.progress.text = [Anime stringForAnimeWatchedStatus:[anime.watched_status intValue]];
    
    cell.rank.text = [anime.user_score intValue] != -1 ? [NSString stringWithFormat:@"%d", [anime.user_score intValue]] : @"";
    cell.type.text = [Anime stringForAnimeType:[anime.type intValue]];
    
    [cell setImageWithItem:anime];
}

- (void)configureMangaCell:(AniListMiniCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Manga *manga = [self.relatedData[indexPath.section] allValues][0][indexPath.row];
    
    cell.title.text = manga.title;
    [cell.title sizeToFit];
    
    cell.progress.text = [Manga stringForMangaReadStatus:[manga.read_status intValue]];

    cell.rank.text = [manga.user_score intValue] != -1 ? [NSString stringWithFormat:@"%d", [manga.user_score intValue]] : @"";
    cell.type.text = [Manga stringForMangaType:[manga.type intValue]];
    
    [cell setImageWithItem:manga];
}


#pragma mark - AniListUserInfoViewControllerDelegate Methods

- (void)userInfoPressed {
    self.navigationItem.backBarButtonItem = [UIBarButtonItem customBackButtonWithTitle:@"Summary"];
}

#pragma mark - UITableView Data Source Methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = [self.relatedData[section] allKeys][0];
    UILabel *label = [UILabel whiteHeaderWithFrame:CGRectMake(0, 0, 320, 60) andFontSize:18];
    label.text = title;
    
    return label;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [AniListMiniCell cellHeight];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.relatedData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.relatedData[section] allValues][0] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    AniListMiniCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AniListMiniCell" owner:self options:nil];
        cell = (AniListMiniCell *)nib[0];
        [(AniListMiniCell *)cell setup];
    }
    
    NSManagedObject *object = [self.relatedData[indexPath.section] allValues][0][indexPath.row];
    
    if([object isKindOfClass:[Anime class]]) {
        [self configureAnimeCell:cell atIndexPath:indexPath];
    }
    else if([object isKindOfClass:[Manga class]]) {
        [self configureMangaCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.relatedTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSManagedObject *object = [self.relatedData[indexPath.section] allValues][0][indexPath.row];
    
    UIViewController *vc;
    
    if([object isKindOfClass:[Anime class]]) {
        Anime *anime = (Anime *)object;
        vc = [[AnimeViewController alloc] init];
        ((AnimeViewController *)vc).anime = anime;
    }
    else if([object isKindOfClass:[Manga class]]) {
        Manga *manga = (Manga *)object;
        vc = [[MangaViewController alloc] init];
        ((MangaViewController *)vc).manga = manga;
    }
    else return;
    
    self.navigationItem.backBarButtonItem = [UIBarButtonItem customBackButtonWithTitle:@"Back"];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int frameOffset = [UIApplication isiOS7] ? -10 : 38;
    if(scrollView.contentOffset.y < frameOffset) {
        [self removeTitle];
    }
    else {
        [self displayTitle];
    }
    
//    AniListNavigationController *navigationController = (AniListNavigationController *)self.navigationController;
//    
//    // Since we know this background will fit the screen height, we can use this value.
//    float height = [UIScreen mainScreen].bounds.size.height;
//    
//    if(scrollView.contentOffset.y <= 0) {
//        navigationController.imageView.frame = CGRectMake(navigationController.imageView.frame.origin.x, 0, navigationController.imageView.frame.size.width, navigationController.imageView.frame.size.height);
//    }
//    else {
//        float yOrigin = -((navigationController.imageView.frame.size.height - height) * (scrollView.contentOffset.y / scrollView.contentSize.height));
//        navigationController.imageView.frame = CGRectMake(navigationController.imageView.frame.origin.x, yOrigin, navigationController.imageView.frame.size.width, navigationController.imageView.frame.size.height);
//    }
}

@end
