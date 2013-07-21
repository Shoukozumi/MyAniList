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

@interface MangaListViewController ()

@end

@implementation MangaListViewController

- (id)init {
    self = [super init];
    if(self) {
        self.title = @"Manga";
        self.sectionHeaders = @[@"Reading", @"Completed", @"On Hold",
                                @"Dropped", @"Plan To Read"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchData) name:kUserLoggedIn object:nil];
    }
    
    return self;
}

- (void)dealloc {
    ALLog(@"MangaList deallocating.");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self fetchData];
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

- (void)fetchData {
    if([UserProfile userIsLoggedIn]) {
        [[MALHTTPClient sharedClient] getMangaListForUser:[[UserProfile profile] username]
                                                  success:^(NSURLRequest *operation, id response) {
                                                      [MangaService addMangaList:(NSDictionary *)response];
                                                      
                                                      [super fetchData];
                                                  }
                                                  failure:^(NSURLRequest *operation, NSError *error) {
                                                      // Derp.
                                                      
                                                      [super fetchData];
                                                  }];
    }
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
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
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Manga *manga = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    AniListNavigationController *navigationController = (AniListNavigationController *)self.navigationController;
    
    MangaViewController *mvc = [[MangaViewController alloc] init];
    mvc.manga = manga;
    mvc.currentYBackgroundPosition = navigationController.imageView.frame.origin.y;
    
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath  {
    
    Manga *manga = [self.fetchedResultsController objectAtIndexPath:indexPath];
    MangaCell *mangaCell = (MangaCell *)cell;
    mangaCell.title.text = manga.title;
    [mangaCell.title addShadow];
    [mangaCell.title sizeToFit];
    
    mangaCell.progress.text = [MangaCell progressTextForManga:manga withSpacing:NO];
    [mangaCell.progress addShadow];
    
    mangaCell.rank.text = [manga.user_score intValue] != -1 ? [NSString stringWithFormat:@"%d", [manga.user_score intValue]] : @"";
    [mangaCell.rank addShadow];
    
    mangaCell.type.text = [Manga stringForMangaType:[manga.type intValue]];
    [mangaCell.type addShadow];
    
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:manga.image_url]];
    UIImage *cachedImage = [manga imageForManga];
    
    if(!cachedImage) {
        [mangaCell.image setImageWithURLRequest:imageRequest placeholderImage:cachedImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            mangaCell.image.alpha = 0.0f;
            mangaCell.image.image = image;
            
            [UIView animateWithDuration:0.3f animations:^{
                mangaCell.image.alpha = 1.0f;
            }];
            
            if(!manga.image) {
                // Save the image onto disk if it doesn't exist or they aren't the same.
                [manga saveImage:image fromRequest:request];
            }
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            // Log failure.
            ALLog(@"Couldn't fetch image at URL %@.", [request.URL absoluteString]);
        }];
    }
    else {
        mangaCell.image.image = cachedImage;
    }

    
}

@end
