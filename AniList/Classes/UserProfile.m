//
//  UserProfile.m
//  AniList
//
//  Created by Corey Roberts on 6/13/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "UserProfile.h"
#import "MALHTTPClient.h"
#import <Crashlytics/Crashlytics.h>

@interface UserProfile()
@property (nonatomic, assign) BOOL contrastEnabled;
@end

@implementation UserProfile

static UserProfile *profile = nil;

+ (UserProfile *)profile {
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        profile = [[UserProfile alloc] init];
    });
    
    return profile;
}

- (id)init {
    self = [super init];
    if(self) {
        NSDictionary *animeStats = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserAnimeStats];
        if(animeStats) {
            self.animeStats = animeStats;
        }
        
        NSDictionary *mangaStats = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserMangaStats];
        if(mangaStats) {
            self.mangaStats = mangaStats;
        }
    }
    
    return self;
}

- (void)setUsername:(NSString *)username andPassword:(NSString *)password {
    profile.username = username;
    profile.password = password;
    
    [[Crashlytics sharedInstance] setUserName:username];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedIn object:nil];
}

- (NSString *)username {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUsernameKey];
}

- (NSString *)password {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kPasswordKey];
}

- (NSString *)email {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kEmailKey];
}

- (void)setUsername:(NSString *)username {
    [[NSUserDefaults standardUserDefaults] setValue:username forKey:kUsernameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setPassword:(NSString *)password {
    [[NSUserDefaults standardUserDefaults] setValue:password forKey:kPasswordKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setEmail:(NSString *)email {
    [[NSUserDefaults standardUserDefaults] setValue:email forKey:kEmailKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Settings Methods

- (BOOL)displayWatching {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDisplayWatching];
}

- (void)setDisplayWatching:(BOOL)displayWatching {
    [[NSUserDefaults standardUserDefaults] setBool:displayWatching forKey:kDisplayWatching];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)displayCompleted {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDisplayCompleted];
}

- (void)setDisplayCompleted:(BOOL)displayCompleted {
    [[NSUserDefaults standardUserDefaults] setBool:displayCompleted forKey:kDisplayCompleted];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)displayOnHold {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDisplayOnHold];
}

- (void)setDisplayOnHold:(BOOL)displayOnHold {
    [[NSUserDefaults standardUserDefaults] setBool:displayOnHold forKey:kDisplayOnHold];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)displayDropped {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDisplayDropped];
}

- (void)setDisplayDropped:(BOOL)displayDropped {
    [[NSUserDefaults standardUserDefaults] setBool:displayDropped forKey:kDisplayDropped];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)displayPlanToWatch {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDisplayPlanToWatch];
}

- (void)setDisplayPlanToWatch:(BOOL)displayPlanToWatch {
    [[NSUserDefaults standardUserDefaults] setBool:displayPlanToWatch forKey:kDisplayPlanToWatch];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAnimeStats];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserMangaStats];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kNotificationTimestampKey];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kEnableContrast];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDisplayWatching];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDisplayCompleted];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDisplayOnHold];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDisplayDropped];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDisplayPlanToWatch];
}

#pragma mark - Public Methods

- (void)logout {
    self.username = nil;
    self.password = nil;
    self.email = nil;
    
    [self resetDefaults];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedOut object:nil];
}

+ (BOOL)userIsLoggedIn {
    return [[NSUserDefaults standardUserDefaults] valueForKey:kUsernameKey] && [[NSUserDefaults standardUserDefaults] valueForKey:kPasswordKey];
}

- (void)fetchProfileWithSuccess:(void (^)(void))success failure:(void (^)(void))failure {
    [[MALHTTPClient sharedClient] getProfileForUser:[[UserProfile profile] username] success:^(id operation, id response) {
        ALLog(@"Got user details.");
        NSDictionary *userProfile = (NSDictionary *)response;
        
        [[UserProfile profile] createAnimeStats:userProfile[@"anime_stats"]];
        [[UserProfile profile] createMangaStats:userProfile[@"manga_stats"]];
        
        self.profileImageURL = [self getUserImageURL:userProfile];
        
        if(success) {
            success();
        }
        
    } failure:^(id operation, NSError *error) {
        ALLog(@"Failed to get user details");
        
        if(failure) {
            failure();
        }
    }];

}

- (NSURLRequest *)getUserImageURL:(NSDictionary *)data {
    NSString *profileImageURL = data[@"avatar_url"];
    return [NSURLRequest requestWithURL:[NSURL URLWithString:profileImageURL]];
}

- (NSString *)animeCellStats {
    if(self.animeStats) {
        return [NSString stringWithFormat:@"%@ finished, %@ total (%@ days)", self.animeStats[kStatsCompleted], self.animeStats[kStatsTotalEntries], self.animeStats[kStatsTotalTimeInDays]];
    }
    
    return @"-";
}

- (NSString *)mangaCellStats {
    if(self.mangaStats) {
        return [NSString stringWithFormat:@"%@ finished, %@ total (%@ days)", self.mangaStats[kStatsCompleted], self.mangaStats[kStatsTotalEntries], self.mangaStats[kStatsTotalTimeInDays]];
    }
    
    return @"-";
}

- (void)createAnimeStats:(NSDictionary *)data {
    @try {
        self.animeStats = @{
                            kStatsTotalTimeInDays   : data[kStatsTotalTimeInDays],
                            kStatsWatching          : data[kStatsWatching],
                            kStatsCompleted         : data[kStatsCompleted],
                            kStatsOnHold            : data[kStatsOnHold],
                            kStatsDropped           : data[kStatsDropped],
                            kStatsPlanToWatch       : data[kStatsPlanToWatch],
                            kStatsTotalEntries      : data[kStatsTotalEntries]
                            };
        
        [[NSUserDefaults standardUserDefaults] setObject:self.animeStats forKey:kUserAnimeStats];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    @catch (NSException *exception) {
        ALLog(@"An exception occurred while creating anime stats: %@", exception);
    }
}

- (void)createMangaStats:(NSDictionary *)data {
    
    @try {
        self.mangaStats = @{
                            kStatsTotalTimeInDays   : data[kStatsTotalTimeInDays],
                            kStatsReading           : data[kStatsReading],
                            kStatsCompleted         : data[kStatsCompleted],
                            kStatsOnHold            : data[kStatsOnHold],
                            kStatsDropped           : data[kStatsDropped],
                            kStatsPlanToRead        : data[kStatsPlanToRead],
                            kStatsTotalEntries      : data[kStatsTotalEntries]
                            };
        
        [[NSUserDefaults standardUserDefaults] setObject:self.mangaStats forKey:kUserMangaStats];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    @catch (NSException *exception) {
        ALLog(@"An exception occurred while creating manga stats: %@", exception);
    }
}

- (NSTimeInterval)lastFetchedNotificationTimestamp {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kNotificationTimestampKey];
}

- (void)setNotificationTimestamp:(NSTimeInterval)timestamp {
    [[NSUserDefaults standardUserDefaults] setInteger:timestamp forKey:kNotificationTimestampKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)shouldShowProTip {
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kProTipNotification];
}

- (void)setProTip {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kProTipNotification];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)contrastEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEnableContrast];
}

- (void)setContrastEnabled:(BOOL)enabled {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kEnableContrast];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
