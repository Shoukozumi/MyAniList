//
//  AnimeService.m
//  AniList
//
//  Created by Corey Roberts on 4/17/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AnimeService.h"
#import "AniListAppDelegate.h"
#import "MALHTTPClient.h"

#define ENTITY_NAME @"Anime"

@interface AnimeService()

@end

static NSArray *cachedAnimeList = nil;

@implementation AnimeService

+ (Anime *)animeForID:(NSNumber *)ID {
    return [self animeForID:ID fromCache:NO];
}

+ (Anime *)animeForID:(NSNumber *)ID fromCache:(BOOL)fromCache {
    fromCache = NO;
    
    if(fromCache) {
        if(!cachedAnimeList) {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY_NAME inManagedObjectContext:[AnimeService managedObjectContext]];
            request.entity = entity;
            request.relationshipKeyPathsForPrefetching = @[@"prequels", @"sequels"];
            request.returnsObjectsAsFaults = NO;
            
            NSError *error = nil;
            cachedAnimeList = [[AnimeService managedObjectContext] executeFetchRequest:request error:&error];
        }
        
        for(Anime *anime in cachedAnimeList) {
            if([anime.anime_id intValue] == [ID intValue])
                return anime;
        }
        
        return nil;
    }
    else {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY_NAME inManagedObjectContext:[AnimeService managedObjectContext]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"anime_id == %d", [ID intValue]];
        request.entity = entity;
        request.predicate = predicate;
        request.fetchLimit = 1;
        
        NSError *error = nil;
        NSArray *results = [[AnimeService managedObjectContext] executeFetchRequest:request error:&error];
        
        if(results.count) {
            return (Anime *)results[0];
        }
        else return nil;
    }
}

+ (BOOL)addAnimeListFromSearch:(NSArray *)data {
    for(NSDictionary *result in data) {
        [AnimeService addAnime:result fromList:YES];
    }
    
    return NO;
}

+ (BOOL)addAnimeList:(NSDictionary *)data {
    
    NSDictionary *animeDetails = data[@"myanimelist"];
    NSDictionary *animeDictionary = animeDetails[@"anime"];
    NSDictionary *animeUserInfo = animeDetails[@"myinfo"];
    
    cachedAnimeList = nil;
    
    MVComputeTimeWithNameAndBlock((const char *)"animelist", ^{
        
        for(NSDictionary *animeItem in animeDictionary) {
            NSMutableDictionary *anime = [[NSMutableDictionary alloc] init];
            
            [anime addEntriesFromDictionary:@{ kID : @([animeItem[@"series_animedb_id"][@"text"] intValue]) } ];
            [anime addEntriesFromDictionary:@{ kUserEndDate : animeItem[@"my_finish_date"][@"text"] }];
            [anime addEntriesFromDictionary:@{ kUserLastUpdated : @([animeItem[@"my_last_updated"][@"text"] intValue]) }];
            [anime addEntriesFromDictionary:@{ kUserStartDate : animeItem[@"my_start_date"][@"text"] }];
            [anime addEntriesFromDictionary:@{ kUserRewatchingStatus : @([animeItem[@"my_rewatching"][@"text"] intValue]) }];
            [anime addEntriesFromDictionary:@{ kUserRewatchingEpisode : @([animeItem[@"my_rewatching_ep"][@"text"] intValue]) }];
            [anime addEntriesFromDictionary:@{ kUserScore : @([animeItem[@"my_score"][@"text"] intValue]) }];
            [anime addEntriesFromDictionary:@{ kUserWatchedStatus : animeItem[@"my_status"][@"text"] }];
            
            // no tag support...yet.
            //        [anime addEntriesFromDictionary:@{ @"user_tags" : animeItem[@"my_tags"][@"text"] }];
            
            [anime addEntriesFromDictionary:@{ kUserWatchedEpisodes : @([animeItem[@"my_watched_episodes"][@"text"] intValue]) }];
            [anime addEntriesFromDictionary:@{ kAirEndDate : animeItem[@"series_end"][@"text"] }];
            [anime addEntriesFromDictionary:@{ kEpisodes : @([animeItem[@"series_episodes"][@"text"] intValue]) }];
            [anime addEntriesFromDictionary:@{ kImageURL : animeItem[@"series_image"][@"text"] }];
            [anime addEntriesFromDictionary:@{ kAirStartDate : animeItem[@"series_start"][@"text"] }];
            [anime addEntriesFromDictionary:@{ kAirStatus : animeItem[@"series_status"][@"text"] }];
            
            // no synonym support...yet.
            //        [anime addEntriesFromDictionary:@{ @"series_synonyms" : animeItem[@"series_synonyms"][@"text"] }];
            
            [anime addEntriesFromDictionary:@{ kTitle : animeItem[@"series_title"][@"text"] }];
            [anime addEntriesFromDictionary:@{ kType : animeItem[@"series_type"][@"text"] }];
            
            [AnimeService addAnime:anime fromList:YES];
        }
        
        [[AnimeService managedObjectContext] save:nil];
    });
    
    return NO;
}

+ (Anime *)addRelatedAnime:(NSDictionary *)data toAnime:(Anime *)anime relationType:(AnimeRelation)relationType {
    Anime *relatedAnime = [AnimeService animeForID:data[@"anime_id"] fromCache:NO];
    
    if(relatedAnime) {
        ALLog(@"Related anime exists.");
    }
    else {
        ALLog(@"Related anime does not exist. Creating.");
        relatedAnime = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:[AnimeService managedObjectContext]];
        relatedAnime.anime_id = [data[@"anime_id"] isKindOfClass:[NSString class]] ? @([data[@"anime_id"] intValue]) : data[@"anime_id"];
        relatedAnime.title = data[kTitle];
    }
    
    switch (relationType) {
        case AnimeRelationPrequel:
            [relatedAnime addSequelsObject:anime];
            [anime addPrequelsObject:relatedAnime];
            break;
        case AnimeRelationSequel:
            [relatedAnime addPrequelsObject:anime];
            [anime addSequelsObject:relatedAnime];
            break;
        default:
            break;
    }
    
    return relatedAnime;
}

+ (Anime *)addAnime:(NSDictionary *)data fromList:(BOOL)fromList {
    Anime *existingAnime = [AnimeService animeForID:data[kID] fromCache:fromList];
    
    if(existingAnime) {
        ALLog(@"Anime exists. Updating details.");
        return [AnimeService editAnime:data fromList:fromList withObject:existingAnime];
    }
    
    NSError *error = nil;
    
    Anime *anime = [NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:[AnimeService managedObjectContext]];
    
    anime.anime_id = [data[kID] isKindOfClass:[NSString class]] ? @([data[kID] intValue]) : data[kID];
    anime.title = data[kTitle];
    
    anime.last_updated = data[kUserLastUpdated];
    
//    anime.synonyms = data[@"other_titles"];
    // english
    // japanese
    
    // rank (global)
    // popularity_rank
    
    if(data[kImageURL] && ![data[kImageURL] isNull])
        anime.image_url = data[kImageURL];
    else if(data[kImage] && ![data[kImage] isNull])
        anime.image_url = data[kImage];
    
    anime.type = @([Anime animeTypeForValue:data[kType]]);
    anime.total_episodes = [data[kEpisodes] isNull] ? @(-1) : [data[kEpisodes] isKindOfClass:[NSString class]] ? @([data[kEpisodes] intValue]) : data[kEpisodes];
    anime.status = @([Anime animeAirStatusForValue:data[kAirStatus]]);
    
    // note: not the user start/end date
    anime.date_start = [NSDate parseDate:data[kAirStartDate]];
    anime.date_finish = [NSDate parseDate:data[kAirEndDate]];
    
    anime.user_date_start = [NSDate parseDate:data[kUserStartDate]];
    anime.user_date_finish = [NSDate parseDate:data[kUserEndDate]];
    
//    anime.classification = data[@"classification"];
//    anime.average_score = data[@"members_score"];
//    anime.average_count = data[@"members_count"];
//    anime.favorited_count = data[@"favorited_count"];
//    anime.synopsis = data[@"synopsis"];
//    anime.genres = data[@"genres"];
//    anime.tags = data[@"tags"];
//    anime.manga_adaptations = data[@"manga_adaptations"];
    
    anime.watched_status = @([Anime animeWatchedStatusForValue:data[kUserWatchedStatus]]);
    anime.current_episode = data[kUserWatchedEpisodes];
    anime.user_score = [data[kUserScore] intValue] == 0 ? @(-1) : [data[kUserScore] isKindOfClass:[NSString class]] ? @([data[kUserScore] intValue]) : data[kUserScore];
    
    if(!fromList)
        [[AnimeService managedObjectContext] save:&error];
    
    if(!error) {
        return anime;
    }
    else return nil;
}

/* Need to cover:
 other_titles -> english, japanese
 rank
 popularity_rank
 classification
 members_score
 members_count
 favorited_count
 synopsis
 genres
 tags
 manga_adaptations
 prequels
 sequels
 side_stories
 parent_story
 character_anime
 spin_offs
 summaries
 altenative_versions
 */

+ (Anime *)editAnime:(NSDictionary *)data fromList:(BOOL)fromList withObject:(Anime *)anime {
    if(!anime) {
        ALLog(@"Anime does not exist; unable to edit!");
        return nil;
    }
    
    NSError *error = nil;
    
    anime.anime_id = [data[kID] isKindOfClass:[NSString class]] ? @([data[kID] intValue]) : data[kID];
    anime.title = [data[kTitle] stringByDecodingHTMLEntities];
    //    anime.synonyms = data[@"other_titles"];
    // english
    // japanese

    // rank (global)
    if(data[kRank] && ![data[kRank] isNull])
        anime.rank = data[kRank];
    
    if(data[kPopularityRank] && ![data[kPopularityRank] isNull])
        anime.popularity_rank = data[kPopularityRank];
    
    // Prequels/sequels
    if(data[kPrequels] && ![data[kPrequels] isNull]) {
        NSArray *prequels = data[kPrequels];
        for(NSDictionary *prequel in prequels) {
            Anime *prequelAnime = [self addRelatedAnime:prequel toAnime:anime relationType:AnimeRelationPrequel];
            if(prequelAnime) {
                ALLog(@"Prequel found for %@ -> %@.", anime.title, prequelAnime.title);
                
                // We do a simple check; have we added anything else besides the ID and title? If so, don't bother attempting to update.
                if([prequelAnime.type intValue] == 0) {
                    [[MALHTTPClient sharedClient] getAnimeDetailsForID:prequelAnime.anime_id success:^(id operation, id response) {
                        [self addAnime:response fromList:NO];
                    } failure:^(id operation, NSError *error) {
                        ALLog(@"Failed to get prequel.");
                    }];
                }
            }
        }
    }
    
    if(data[kSequels] && ![data[kSequels] isNull]) {
        NSArray *sequels = data[kSequels];
        for(NSDictionary *sequel in sequels) {
            Anime *sequelAnime = [self addRelatedAnime:sequel toAnime:anime relationType:AnimeRelationSequel];
            if(sequelAnime) {
                ALLog(@"Sequel found for %@ -> %@.", anime.title, sequelAnime.title);
                
                // We do a simple check; have we added anything else besides the ID and title? If so, don't bother attempting to update.
                if([sequelAnime.type intValue] == 0) {
                    [[MALHTTPClient sharedClient] getAnimeDetailsForID:sequelAnime.anime_id success:^(id operation, id response) {
                        [self addAnime:response fromList:NO];
                    } failure:^(id operation, NSError *error) {
                        ALLog(@"Failed to get sequel.");
                    }];
                }
            }
        }
    }
    
    if(data[kImageURL] && ![data[kImageURL] isNull])
        anime.image_url = data[kImageURL];
    
    anime.type = @([Anime animeTypeForValue:data[kType]]);
    anime.total_episodes = [data[kEpisodes] isNull] ? @(-1) : [data[kEpisodes] isKindOfClass:[NSString class]] ? @([data[kEpisodes] intValue]) : data[kEpisodes];
    anime.status = @([Anime animeAirStatusForValue:data[kAirStatus]]);
    
    if(data[kAirStartDate] && ![data[kAirStartDate] isNull])
        anime.date_start = [NSDate parseDate:data[kAirStartDate]];
    if(data[kAirEndDate] && ![data[kAirEndDate] isNull])
        anime.date_finish = [NSDate parseDate:data[kAirEndDate]];
    
    //    anime.classification = data[@"classification"];
    if(data[kMembersScore] && ![data[kMembersScore] isNull])
        anime.average_score = [data[kMembersScore] isKindOfClass:[NSString class]] ? @([data[kMembersScore] doubleValue]) : data[kMembersScore];
    if(data[kMembersCount] &&![data[kMembersCount] isNull])
        anime.average_count = data[kMembersCount];
    if(data[kFavoritedCount] &&![data[kFavoritedCount] isNull])
        anime.favorited_count = data[kFavoritedCount];
    if(data[kSynopsis] &&![data[kSynopsis] isNull]) {
        anime.synopsis = [((NSString *)data[kSynopsis]) cleanHTMLTags];
        anime.synopsis = [anime.synopsis stringByConvertingHTMLToPlainText];
    }
    //    anime.genres = data[@"genres"];
    //    anime.tags = data[@"tags"];
    //    anime.manga_adaptations = data[@"manga_adaptations"];
    
    
    
    // User details below.
    
    NSNumber *lastUpdated = data[kUserLastUpdated];
    
    // If the last time we updated (according to the server) is less than what we get from the server,
    // don't bother updating user details.
    if(lastUpdated && [lastUpdated intValue] <= [anime.last_updated intValue]) {
        ALLog(@"Update times match, no need to update user data.");
    }
    else {
        ALLog(@"Update times differ, updating user data...");
        
        if(data[kUserStartDate] && ![data[kUserStartDate] isNull])
            anime.user_date_start = [NSDate parseDate:data[kUserStartDate]];
        if(data[kUserEndDate] && ![data[kUserEndDate] isNull])
            anime.user_date_finish = [NSDate parseDate:data[kUserEndDate]];
        
        if(data[kUserWatchedStatus] && ![data[kUserWatchedStatus] isNull])
            anime.watched_status = @([Anime animeWatchedStatusForValue:data[kUserWatchedStatus]]);
        
        if(data[kUserWatchedEpisodes] && ![data[kUserWatchedEpisodes] isNull])
            anime.current_episode = data[kUserWatchedEpisodes];
        
        if(data[kUserScore] && ![data[kUserScore] isNull])
            anime.user_score = ([data[kUserScore] isNull] || [data[kUserScore] intValue] == 0) ? @(-1) : [data[kUserScore] isKindOfClass:[NSString class]] ? @([data[kUserScore] intValue]) : data[kUserScore];
    }
    
    if(!fromList)
        [[AnimeService managedObjectContext] save:&error];
    
    if(!error) {
        return anime;
    }
    else return nil;

}


+ (Anime *)editAnime:(NSDictionary *)data fromList:(BOOL)fromList {
    fromList = NO;
    Anime *anime = [AnimeService animeForID:data[@"id"] fromCache:fromList];
    if(!anime) {
        ALLog(@"Unable to edit anime; anime does not exist!");
        return nil;
    }
    
    return [self editAnime:data fromList:fromList withObject:anime];
}

+ (void)deleteAnime:(Anime *)anime {
    NSError *error = nil;
    
    [[AnimeService managedObjectContext] deleteObject:anime];
    [[AnimeService managedObjectContext] save:&error];
    
    if(!error) {
        ALLog(@"There was an error trying to delete this anime with ID (%d).", [anime.anime_id intValue]);
    }
}

+ (NSManagedObjectContext *)managedObjectContext {
    AniListAppDelegate *delegate = (AniListAppDelegate *)[UIApplication sharedApplication].delegate;
    return delegate.managedObjectContext;
}

#pragma mark - Data Conversion Methods

+ (NSString *)animeToXML:(NSNumber *)animeID {
    
    /*
     <?xml version="1.0" encoding="UTF-8"?>
     <entry>
     <episode>11</episode>
     <status>1</status>
     <score>7</score>
     <downloaded_episodes></downloaded_episodes>
     <storage_type></storage_type>
     <storage_value></storage_value>
     <times_rewatched></times_rewatched>
     <rewatch_value></rewatch_value>
     <date_start></date_start>
     <date_finish></date_finish>
     <priority></priority>
     <enable_discussion></enable_discussion>
     <enable_rewatching></enable_rewatching>
     <comments></comments>
     <fansub_group></fansub_group>
     <tags>test tag, 2nd tag</tags>
     </entry>
     */
    
    Anime *anime = [AnimeService animeForID:animeID];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMddyyyy";
    
    NSString *startDate = [dateFormatter stringFromDate:anime.user_date_start];
    NSString *endDate = [dateFormatter stringFromDate:anime.user_date_finish];
    
    NSMutableString *XML = [NSMutableString stringWithString:@"<entry>"];
    [XML appendString:[NSString stringWithFormat:@"<episode>%d</episode>", [anime.current_episode intValue]]];
    [XML appendString:[NSString stringWithFormat:@"<status>%d</status>", [anime.watched_status intValue]]];

    if([anime.user_score intValue] > 0)
        [XML appendString:[NSString stringWithFormat:@"<score>%d</score>", [anime.user_score intValue]]];
    
    if(startDate)
        [XML appendString:[NSString stringWithFormat:@"<date_start>%@</date_start>", startDate]];
    
    if(endDate)
        [XML appendString:[NSString stringWithFormat:@"<date_finish>%@</date_finish>", endDate]];

    [XML appendString:@"</entry>"];
    
    return XML;
}

@end
