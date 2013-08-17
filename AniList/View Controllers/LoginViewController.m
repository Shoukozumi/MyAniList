//
//  LoginViewController.m
//  AniList
//
//  Created by Corey Roberts on 6/13/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "SWRevealViewController.h"
#import "UserProfile.h"
#import "AniListAppDelegate.h"
#import "MALHTTPClient.h"
#import "AniListNavigationController.h"

@interface LoginViewController ()
@property (nonatomic, weak) IBOutlet UITextField *username;
@property (nonatomic, weak) IBOutlet UITextField *password;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *welcomeView;
@property (nonatomic, weak) IBOutlet UIView *organizeView;
@property (nonatomic, weak) IBOutlet UIView *discoverView;
@property (nonatomic, weak) IBOutlet UIView *compareView;
@property (nonatomic, weak) IBOutlet UIView *loginView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIButton *skipToLoginButton;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) UIView *backgroundView;

- (IBAction)skipToLoginButtonPressed:(id)sender;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)backgroundButtonPressed:(id)sender;

@end

@implementation LoginViewController

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
    
    AniListNavigationController *nvc = ((AniListNavigationController *)self.revealViewController.frontViewController);
    
    UIImage *backgroundImage = [UIImage imageNamed:@"intro_background.png"];

    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-30, 0, backgroundImage.size.width, [UIScreen mainScreen].bounds.size.height)];
    
    backgroundImageView.image = backgroundImage;
    
    UIView *overlay = [[UIView alloc] initWithFrame:backgroundImageView.frame];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.75f];
    
    UIView *topOverlay = [[UIView alloc] initWithFrame:backgroundImageView.frame];
    topOverlay.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.75f];
    
    self.backgroundView = [[UIView alloc] initWithFrame:backgroundImageView.frame];
    
    [self.backgroundView addSubview:backgroundImageView];
    [self.backgroundView addSubview:overlay];
    [self.backgroundView addSubview:topOverlay];
    
    [self.view addSubview:self.backgroundView];
    [self.view sendSubviewToBack:self.backgroundView];
    
    self.scrollView.contentSize = CGSizeMake(self.welcomeView.frame.size.width * 5, self.welcomeView.frame.size.height);
    
    [self.scrollView addSubview:self.welcomeView];
    self.welcomeView.frame = CGRectMake(0, 0, self.welcomeView.frame.size.width, self.welcomeView.frame.size.height);
    self.welcomeView.backgroundColor = [UIColor clearColor];
    
    [self.scrollView addSubview:self.organizeView];
    self.organizeView.frame = CGRectMake(self.welcomeView.frame.origin.x + self.welcomeView.frame.size.width, 0, self.organizeView.frame.size.width, self.organizeView.frame.size.height);
    self.organizeView.backgroundColor = [UIColor clearColor];
    
    [self.scrollView addSubview:self.discoverView];
    self.discoverView.frame = CGRectMake(self.organizeView.frame.origin.x + self.organizeView.frame.size.width, 0, self.discoverView.frame.size.width, self.discoverView.frame.size.height);
    self.discoverView.backgroundColor = [UIColor clearColor];
    
    [self.scrollView addSubview:self.compareView];
    self.compareView.frame = CGRectMake(self.discoverView.frame.origin.x + self.discoverView.frame.size.width, 0, self.compareView.frame.size.width, self.compareView.frame.size.height);
    self.compareView.backgroundColor = [UIColor clearColor];
    
    [self.scrollView addSubview:self.loginView];
    self.loginView.frame = CGRectMake(self.compareView.frame.origin.x + self.compareView.frame.size.width, 0, self.loginView.frame.size.width, self.loginView.frame.size.height);
    self.loginView.backgroundColor = [UIColor clearColor];
    
    self.indicator.alpha = 0.0f;
    self.statusLabel.text = @"";
    self.statusLabel.alpha = 0.0f;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(-50, 0, backgroundImageView.frame.size.width+50, backgroundImageView.frame.size.height*2);
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1.0f alpha:0.25] CGColor], (id)[[UIColor colorWithWhite:0.0f alpha:1.0] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.0, 0.15f);
    gradient.endPoint = CGPointMake(0.0f, 0.30f);
    
    overlay.layer.mask = gradient;
    
    CAGradientLayer *topGradient = [CAGradientLayer layer];
    topGradient.frame = CGRectMake(-50, 0, backgroundImageView.frame.size.width+50, backgroundImageView.frame.size.height*2);
    topGradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1.0f alpha:1.0f] CGColor], (id)[[UIColor colorWithWhite:0.0f alpha:0.35f] CGColor], nil];
    
    topGradient.startPoint = CGPointMake(0.0, 0.00f);
    topGradient.endPoint = CGPointMake(0.0f, 0.10f);

    topOverlay.layer.mask = topGradient;
    
    nvc.navigationBar.hidden = YES;
    if([[UIDevice currentDevice].systemVersion compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        //        nvc.navigationBar.barTintColor = [UIColor clearColor];
    }
    else {

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction Methods

- (IBAction)skipToLoginButtonPressed:(id)sender {
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.scrollView scrollRectToVisible:self.loginView.frame animated:NO];
                     }
                     completion:nil];
}

- (IBAction)loginButtonPressed:(id)sender {
    [UIView animateWithDuration:0.3f animations:^{
        self.indicator.alpha = 1.0f;
        self.statusLabel.alpha = 0.0f;
        self.loginButton.alpha = 0.5f;
        self.loginButton.userInteractionEnabled = NO;
        self.username.enabled = NO;
        self.password.enabled = NO;
    }];
    [[MALHTTPClient sharedClient] loginWithUsername:self.username.text andPassword:self.password.text success:^(id operation, id response) {
        [[UserProfile profile] setUsername:self.username.text andPassword:self.password.text];
        ALLog(@"Logged in!");
        [self revokeLoginScreen];
        
    } failure:^(id operation, NSError *error) {
        ALLog(@"Could not log in.");
        // Error logic to handle failure.
        [UIView animateWithDuration:0.3f animations:^{
            self.indicator.alpha = 0.0f;
            self.statusLabel.alpha = 1.0f;
            self.statusLabel.text = @"Couldn't log in. Please try again.";
            self.loginButton.alpha = 1.0f;
            self.loginButton.userInteractionEnabled = YES;
            self.username.enabled = YES;
            self.password.enabled = YES;
        }];
    }];
}

- (IBAction)backgroundButtonPressed:(id)sender {
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
}

#pragma mark - Screen Revoke Methods

- (void)revokeLoginScreen {
    if([UserProfile userIsLoggedIn]) {
        AniListAppDelegate *delegate = (AniListAppDelegate *)[UIApplication sharedApplication].delegate;
        SWRevealViewController *rvc = (SWRevealViewController *)delegate.window.rootViewController;
        AniListNavigationController *nvc = (AniListNavigationController *)rvc.frontViewController;
        nvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        [nvc dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(textField == self.username) {
        if([self.username.text isEqualToString:@"Username"]) {
            self.username.text = @"";
        }
    }
    
    if(textField == self.password) {
        if([self.password.text isEqualToString:@"Password"]) {
            self.password.text = @"";
            self.password.secureTextEntry = YES;
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.username) {
        [self.password becomeFirstResponder];
    }
    else if(textField == self.password) {
        [self.password resignFirstResponder];
        [self loginButtonPressed:nil];
    }
    
    return YES;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Since we know this background will fit the screen height, we can use this value.
    float width = [UIScreen mainScreen].bounds.size.width;
    
    if(scrollView.contentSize.width > 400) {
        float xOrigin = -((self.backgroundView.frame.size.width - width) * (scrollView.contentOffset.x / scrollView.contentSize.width));
        self.backgroundView.frame = CGRectMake(xOrigin - 30.0f, 0, self.backgroundView.frame.size.width, self.backgroundView.frame.size.height);
    }
}

@end
