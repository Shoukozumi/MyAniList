//
//  UIView+AniList.m
//  AniList
//
//  Created by Corey Roberts on 6/2/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "UIView+AniList.h"
#import "TTTAttributedLabel.h"

@implementation UIView (AniList)

+ (UIView *)tableHeaderWithPrimaryText:(NSString *)primaryString andSecondaryText:(NSString *)secondaryString isCollapsible:(BOOL)collapsible {
    
    UIView *view = [UIView tableHeaderWithPrimaryText:primaryString andSecondaryText:secondaryString];
    
    if(collapsible) {
        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chevron.png"]];
        [view addSubview:chevron];
        chevron.frame = CGRectMake(view.frame.size.width - 20, view.frame.size.height / 2 - chevron.frame.size.height / 2, chevron.frame.size.width, chevron.frame.size.height);
    }
    
    return view;
}

+ (UIView *)tableHeaderWithPrimaryText:(NSString *)primaryString andSecondaryText:(NSString *)secondaryString {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 320, 44)];
    view.backgroundColor = [UIColor clearColor];
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(20, 0, 300, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.text = [NSString stringWithFormat:@"%@ (%@)", primaryString, secondaryString];
    
    [view addSubview:label];
    
    [UILabel setAttributesForLabel:label withPrimaryText:primaryString andSecondaryText:[NSString stringWithFormat:@"(%@)", secondaryString]];
    
    return view;
}

+ (UIView *)tableFooterWithError {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    view.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 330, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont defaultFontWithSize:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [NSString stringWithFormat:@"Couldn't load list. Pull to try again."];
    
    [view addSubview:label];
    
    return view;
}

+ (UIView *)versionFooter {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 20)];
    view.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor darkGrayColor];
    label.alpha = 0.4f;
    label.font = [UIFont defaultFontWithSize:13];
    label.textAlignment = NSTextAlignmentCenter;
    
    NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    
    label.text = [NSString stringWithFormat:@"AniList %@", version];
    
    [view addSubview:label];
    
    return view;
}

- (void)animateOut {
    if([UIApplication isiOS7]) {
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.alpha = 0.0f;
                         }
                         completion:nil];
    }
}

- (void)animateIn {
    if([UIApplication isiOS7]) {
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.alpha = 1.0f;
                         }
                         completion:nil];
    }
}

@end
