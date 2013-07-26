//
//  MALHTTPClient.m
//  AniList
//
//  Created by Corey Roberts on 5/27/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "MALHTTPClient.h"
#import "XMLReader.h"
#import "AnimeService.h"
#import "MangaService.h"

#define MAL_OFFICIAL_API_BASE_URL       @"http://myanimelist.net"

@interface MALHTTPClient()
- (void)setUsername:(NSString *)username andPassword:(NSString *)password;
- (void)authenticate;
@end

@implementation MALHTTPClient

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if(!self)
        return nil;
    
    [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/xml"];
    [self setParameterEncoding:AFFormURLParameterEncoding];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    return self;
}

#pragma mark - Singleton Methods

+ (MALHTTPClient *)sharedClient {
    static dispatch_once_t pred;
    static MALHTTPClient *sharedClient = nil;
    
    dispatch_once(&pred, ^{
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:MAL_OFFICIAL_API_BASE_URL]];
    });
    
    return sharedClient;
}

#pragma mark - Private Methods

- (void)setUsername:(NSString *)username andPassword:(NSString *)password {
    [self clearAuthorizationHeader];
    [self setAuthorizationHeaderWithUsername:username password:password];
}

- (void)authenticate {
    if([UserProfile userIsLoggedIn])
        [self setUsername:[[UserProfile profile] username] andPassword:[[UserProfile profile] password]];
    else NSAssert(nil, @"Username and password must be valid!");
}

#pragma mark - Profile Methods

- (void)getProfileForUser:(NSString *)user success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting user profile...");
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:[NSString stringWithFormat:@"/profile/%@", user]
                               parameters:@{}
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      ALLog(@"Profile details fetched!");
                                      success(operation, responseObject);
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
                                  }];
}

#pragma mark - User Authentication Methods

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Logging in with username '%@'...,", username);
    
    [[MALHTTPClient sharedClient] setUsername:username andPassword:password];
    [[MALHTTPClient sharedClient] getPath:@"/api/account/verify_credentials.xml"
                               parameters:@{}
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      ALLog(@"Logged in successfully!");
                                      success(operation, responseObject);
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
                                  }];
}

#pragma mark - Anime Request Methods

- (void)getAnimeListForUser:(NSString *)user initialFetch:(BOOL)initialFetch success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting anime list for user '%@'...", user);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"type" : @"anime", @"u" : user }];
    
    if(initialFetch) {
        [parameters addEntriesFromDictionary:@{ @"status"  : @"all" }];
    }
    
    [[MALUserClient sharedClient] getPath:@"/malappinfo.php"
                               parameters:parameters
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      NSError *parseError = nil;
                                      NSDictionary *xmlDictionary = [XMLReader dictionaryForXMLData:operation.responseData error:&parseError];
                                      success(operation, xmlDictionary);
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
                                  }];
}

- (void)getTopAnimeForType:(AnimeType)animeType atPage:(NSNumber *)page success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting top list for anime type %@...", [Anime stringForAnimeType:animeType]);
    
    NSString *path = @"/anime/top";
    
    NSDictionary *parameters = @{
//                                 @"type" : [Anime stringForAnimeType:animeType], // not working at the moment.
                                 @"page" : page
                                 };
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       failure(operation, error);
                                   }];
}

- (void)getPopularAnimeForType:(AnimeType)animeType atPage:(NSNumber *)page success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting popular list for anime type %@...", [Anime stringForAnimeType:animeType]);
    
    NSString *path = @"/anime/popular";
    
    NSDictionary *parameters = @{
                                 // @"type" : [Anime stringForAnimeType:animeType], // not working at the moment.
                                 @"page" : page
                                 };
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       // If no objects come back, consider the response as failed.
                                       if(((NSArray *)responseObject).count == 0)
                                           failure(operation, nil);
                                       else
                                           success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       failure(operation, error);
                                   }];
}

- (void)getUpcomingAnimeFromDate:(NSDate *)date atPage:(NSNumber *)page success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting upcoming anime from date %@...", date);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    NSString *path = @"/anime/upcoming";
    
    NSDictionary *parameters = @{
                                 @"start_date" : dateString
                                 };
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       failure(operation, error);
                                   }];
}

- (void)getJustAddedAnimeAtPage:(NSNumber *)page success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting just added anime at page %d.", [page intValue]);

    NSString *path = @"/anime/just_added";
    
    NSDictionary *parameters = @{
                                 @"page" : page
                                 };
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       failure(operation, error);
                                   }];
}

- (void)getAnimeDetailsForID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    ALLog(@"Getting anime details for ID %d...", [animeID intValue]);
    
    NSString *path = [NSString stringWithFormat:@"/anime/%d", [animeID intValue]];

    NSDictionary *parameters = @{ @"mine" : @"1" };
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       failure(operation, error);
                                   }];
}

- (void)addAnimeToListWithID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/api/animelist/add/%d.xml", [animeID intValue]];
    
    NSString *animeToXML = [AnimeService animeToXML:animeID];
    NSDictionary *parameters = @{ @"data" : animeToXML };
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] postPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       ALLog(@"response: %@", operation.responseString);
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       ALLog(@"failed response: %@", operation.responseString);
                                       failure(operation, error);
                                   }];
    
}

- (void)updateDetailsForAnimeWithID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/api/animelist/update/%d.xml", [animeID intValue]];

    NSString *animeToXML = [AnimeService animeToXML:animeID];
    NSDictionary *parameters = @{ @"data" : animeToXML };
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] postPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       ALLog(@"response: %@", operation.responseString);
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       failure(operation, error);
                                   }];
    
}

- (void)deleteAnimeWithID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/api/animelist/delete/%d.xml", [animeID intValue]];
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] deletePath:path
                                  parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         ALLog(@"Anime deleted: %@", operation.responseString);
                                         success(operation, responseObject);
                                     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         ALLog(@"Anime failed to delete. Please try again later.");
                                         failure(operation, error);
                                     }];
}

- (void)searchForAnimeWithQuery:(NSString *)query success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    //http://myanimelist.net/api/anime/search.xml?q=bleach
    
    NSString *path = [NSString stringWithFormat:@"/api/anime/search.xml?q=%@", query];
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] getPath:path
                               parameters:@{}
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                          NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//                                          ALLog(@"result: %@", result);
                                          result = [result stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                                          result = [result stringByDecodingHTMLEntities];
                                          
                                          // If there still are ampersands out there, escape them.
                                          result = [result stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
                                          result = [result stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
//                                          ALLog(@"result: %@", result);
                                          NSError *parseError = nil;
                                          NSDictionary *xmlDictionary = [XMLReader dictionaryForXMLString:result error:&parseError];
                                          
                                          NSArray *animelist;
                                          id list = xmlDictionary[@"anime"][@"entry"];
                                          
                                          if([list isKindOfClass:[NSDictionary class]]) {
                                              animelist = @[xmlDictionary[@"anime"][@"entry"]];
                                          }
                                          else if([list isKindOfClass:[NSArray class]]) {
                                              animelist = xmlDictionary[@"anime"][@"entry"];
                                          }
                                          
                                          NSMutableArray *cleanedList = [NSMutableArray array];
                                          NSMutableDictionary *cleanedAnime;
                                          for(NSDictionary *anime in animelist) {
                                              cleanedAnime = [[anime cleanupTextTags] mutableCopy];
                                              if([cleanedAnime valueForKey:@"score"] != nil) {
                                                  NSString *value = cleanedAnime[@"score"];
                                                  [cleanedAnime addEntriesFromDictionary:@{ @"members_score" : value }];
                                                  [cleanedAnime removeObjectForKey:@"score"];
                                              }
                                              [cleanedList addObject:cleanedAnime];
                                          }
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              success(operation, cleanedList);
                                          });
                                      });
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
                                  }];
}

- (void)searchForMangaWithQuery:(NSString *)query success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/api/manga/search.xml?q=%@", query];
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] getPath:path
                               parameters:@{}
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      
                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                          NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                                          
                                          result = [result stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                                          result = [result stringByDecodingHTMLEntities];
                                          
                                          // If there still are ampersands out there, escape them.
                                          result = [result stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
                                          result = [result stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
                                          
                                          NSError *parseError = nil;
                                          NSDictionary *xmlDictionary = [XMLReader dictionaryForXMLString:result error:&parseError];
                                          
                                          NSArray *mangalist;
                                          id list = xmlDictionary[@"manga"][@"entry"];
                                          
                                          if([list isKindOfClass:[NSDictionary class]]) {
                                              mangalist = @[xmlDictionary[@"manga"][@"entry"]];
                                          }
                                          else if([list isKindOfClass:[NSArray class]]) {
                                              mangalist = xmlDictionary[@"manga"][@"entry"];
                                          }
                                          
                                          NSMutableArray *cleanedList = [NSMutableArray array];
                                          NSMutableDictionary *cleanedManga;
                                          for(NSDictionary *manga in mangalist) {
                                              cleanedManga = [[manga cleanupTextTags] mutableCopy];
                                              if([cleanedManga valueForKey:@"score"] != nil) {
                                                  NSString *value = cleanedManga[@"score"];
                                                  [cleanedManga addEntriesFromDictionary:@{ @"members_score" : value }];
                                                  [cleanedManga removeObjectForKey:@"score"];
                                              }
                                              [cleanedList addObject:cleanedManga];
                                          }
                                          
                                          success(operation, cleanedList);
                                      });
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
                                  }];
}

#pragma mark - Manga Request Methods

- (void)getMangaListForUser:(NSString *)user initialFetch:(BOOL)initialFetch success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"type" : @"manga", @"u" : user }];
    
//    if(initialFetch) {
        [parameters addEntriesFromDictionary:@{ @"status"  : @"all" }];
//    }
    
    [[MALUserClient sharedClient] getPath:@"/malappinfo.php"
                               parameters:parameters
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      NSError *parseError = nil;
                                      NSDictionary *xmlDictionary = [XMLReader dictionaryForXMLData:operation.responseData error:&parseError];
                                      success(operation, xmlDictionary);
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
    }];
}

- (void)getMangaDetailsForID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/manga/%d", [mangaID intValue]];
    
    NSDictionary *parameters = @{ @"mine" : @"1" };
    
    [[UMALHTTPClient sharedClient] authenticate];
    [[UMALHTTPClient sharedClient] getPath:path
                               parameters:parameters
                                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                      success(operation, responseObject);
                                  }
                                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                      failure(operation, error);
                                  }];
}

- (void)addMangaToListWithID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/api/mangalist/add/%d.xml", [mangaID intValue]];
    
    NSString *mangaToXML = [MangaService mangaToXML:mangaID];
    NSDictionary *parameters = @{ @"data" : mangaToXML };
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] postPath:path
                                parameters:parameters
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       ALLog(@"response: %@", operation.responseString);
                                       success(operation, responseObject);
                                   }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       ALLog(@"failed response: %@", operation.responseString);
                                       failure(operation, error);
                                   }];
    
}

- (void)updateDetailsForMangaWithID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"api/mangalist/update/%d.xml", [mangaID intValue]];
    
    NSString *mangaToXML = [MangaService mangaToXML:mangaID];
    NSDictionary *parameters = @{ @"data" : mangaToXML };
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] postPath:path
                                 parameters:parameters
                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        ALLog(@"response: %@", operation.responseString);
                                        success(operation, responseObject);
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        failure(operation, error);
                                    }];
    
}

- (void)deleteMangaWithID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure {
    NSString *path = [NSString stringWithFormat:@"/api/mangalist/delete/%d.xml", [mangaID intValue]];
    
    [[MALHTTPClient sharedClient] authenticate];
    [[MALHTTPClient sharedClient] deletePath:path
                                  parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         ALLog(@"Manga deleted: %@", operation.responseString);
                                         success(operation, responseObject);
                                     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         ALLog(@"Manga failed to delete. Please try again later.");
                                         failure(operation, error);
                                     }];
}

@end
