//
//  SettingsViewController.m
//  AniList
//
//  Created by Corey Roberts on 6/23/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "SettingsViewController.h"
#import "AniListTableView.h"

@interface SettingsViewController ()
@property (nonatomic, weak) IBOutlet UIView *maskView;
@property (nonatomic, weak) IBOutlet AniListTableView *tableView;
@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    SWRevealViewController *revealController = self.revealViewController;
    
    UINavigationController *nvc = ((UINavigationController *)self.revealViewController.frontViewController);
    
    // This value is implicitly set to YES in iOS 7.0.
    nvc.navigationBar.translucent = YES; // Setting this slides the view up, underneath the nav bar (otherwise it'll appear black)
    
    if([[UIDevice currentDevice].systemVersion compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //        nvc.navigationBar.barTintColor = [UIColor clearColor];
    }
    else {
        const float colorMask[6] = {222, 255, 222, 255, 222, 255};
        UIImage *img = [[UIImage alloc] init];
        UIImage *maskedImage = [UIImage imageWithCGImage: CGImageCreateWithMaskingColors(img.CGImage, colorMask)];
        
        [nvc.navigationBar setShadowImage:[[UIImage alloc] init]];
        [nvc.navigationBar setBackgroundImage:maskedImage forBarMetrics:UIBarMetricsDefault];
    }
    
#warning - Why does this break for unit testing?
    if(revealController) {
        [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    }
    
    self.view.backgroundColor = [UIColor clearColor];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.maskView.frame;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.0, 0.075f);
    gradient.endPoint = CGPointMake(0.0f, 0.10f);
    
    self.maskView.layer.mask = gradient;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:revealController action:@selector(revealToggle:)];
    
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = @"Hey";
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end