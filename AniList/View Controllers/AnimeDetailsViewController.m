//
//  AnimeDetailsViewController.m
//  AniList
//
//  Created by Corey Roberts on 6/2/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AnimeDetailsViewController.h"
#import "AnimeService.h"
#import "Anime.h"
#import "MALHTTPClient.h"

@implementation AnimeDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAnime:) name:kAnimeDidUpdate object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.anime) {
        self.titleLabel.text = self.anime.title;
        
        self.type.text = [self animeTypeText];
        
        self.seriesStatus.text = [self airText];
        [self.seriesStatus sizeToFit];
        
        // This block of text requires data.
        if([self.anime hasAdditionalDetails]) {
            [self displayDetailsViewAnimated:NO];
        }
        
        [self setupPosterForObject:self.anime];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIView Methods

- (void)displayDetailsViewAnimated:(BOOL)animated {
    if([self.anime.average_score doubleValue] != 0)
        self.score.text = [NSString stringWithFormat:@"Score: %0.02f", [self.anime.average_score doubleValue]];
    else self.score.hidden = YES;
    
    if([self.anime.average_count intValue] != 0)
        self.totalPeopleScored.text = [NSString stringWithFormat:@"(by %d people)", [self.anime.average_count intValue]];
    else self.totalPeopleScored.hidden = YES;
    
    if([self.anime.rank intValue] != 0)
        self.rank.text = [NSString stringWithFormat:@"Rank: #%d", [self.anime.rank intValue]];
    else self.rank.hidden = YES;
    
    if([self.anime.popularity_rank intValue] != 0)
        self.popularity.text = [NSString stringWithFormat:@"Popularity: #%d", [self.anime.popularity_rank intValue]];
    else self.popularity.hidden = YES;
    
    if(self.popularity.hidden && self.rank.hidden && self.totalPeopleScored.hidden) {
        self.score.frame = self.popularity.frame;
    }
    
    [super displayDetailsViewAnimated:animated];
}

#pragma mark - UILabel Management Methods

- (NSString *)airText {    
    NSString *text = @"";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM dd, yyyy";

    NSString *startDate = [dateFormatter stringFromDate:self.anime.date_start];
    NSString *finishDate = [dateFormatter stringFromDate:self.anime.date_finish];
    
    if(self.anime.date_start) {
        text = [text stringByAppendingFormat:@"Started airing on %@ ", startDate];
    }
    
    if(self.anime.date_finish) {
        text = [text stringByAppendingFormat:@"and finished on %@", finishDate];
    }
    else if([self.anime.status intValue] == AnimeAirStatusCurrentlyAiring) {
        text = [text stringByAppendingString:@"and is still airing"];
    }
    
    if(self.anime.date_start && self.anime.date_finish && [self.anime.date_start timeIntervalSince1970] == [self.anime.date_finish timeIntervalSince1970]) {
        
        if([self.anime.status intValue] == AnimeAirStatusFinishedAiring)
            text = [NSString stringWithFormat:@"Aired on %@ ", startDate];
        if([self.anime.status intValue] == AnimeAirStatusNotYetAired)
            text = [NSString stringWithFormat:@"Will air on %@ ", startDate];
    }
    else if(!self.anime.date_start && !self.anime.date_finish) {
        text = @"Airing date unknown";
    }
    
    return text;
}

- (NSString *)animeTypeText {
    
    BOOL plural = [self.anime.total_episodes intValue] != 1;
    
    NSString *text = @"";
    
    NSString *episodeText = plural ? @"episodes" : @"episode";
    NSString *musicText = plural ? @"songs" : @"song";
    NSString *animeType = [Anime stringForAnimeType:[self.anime.type intValue]];
    int numberOfEpisodes = [self.anime.total_episodes intValue];

    NSString *episodeValue = @"";
    NSString *episodeCount = [NSString stringWithFormat:@"%d", numberOfEpisodes];
    NSString *unknownCount = @"?";
    
    episodeValue = [self.anime.total_episodes intValue] < 1 ? unknownCount : episodeCount;
    
    switch([self.anime.type intValue]) {
        case AnimeTypeTV: {
            text = [NSString stringWithFormat:@"%@, %@ %@", animeType, episodeValue, episodeText];
            break;
        }
        case AnimeTypeSpecial: {
            text = [NSString stringWithFormat:@"%@, %@ %@", animeType, episodeValue, episodeText];
            break;
        }
        case AnimeTypeOVA: {
            text = [NSString stringWithFormat:@"%@, %@ %@", animeType, episodeValue, episodeText];
            break;
        }
        case AnimeTypeONA: {
            text = [NSString stringWithFormat:@"%@, %@ %@", animeType, episodeValue, episodeText];
            break;
        }
        case AnimeTypeMusic: {
            text = [NSString stringWithFormat:@"%@, %@ %@", animeType, episodeValue, musicText];
            break;
        }
        case AnimeTypeMovie: {
            text = [NSString stringWithFormat:@"%@", animeType];
            break;
        }
        case AnimeTypeUnknown:
        default: {
            text = [NSString stringWithFormat:@"%@ %@", episodeValue, episodeText];
            break;
        }
    }
    
    return text;
}

#pragma mark - NSNotification Methods

- (void)updateAnime:(NSNotification *)notification {
    BOOL didUpdate = [((NSNumber *)notification.object) boolValue];
    
    if(didUpdate) {
        [self displayDetailsViewAnimated:YES];
    }
    else {
        if([self.anime hasAdditionalDetails]) {
            [self displayDetailsViewAnimated:YES];
        }
        else {
            [self displayErrorMessage];
        }
    }
}

@end
