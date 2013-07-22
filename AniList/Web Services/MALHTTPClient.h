//
//  MALHTTPClient.h
//  AniList
//
//  Created by Corey Roberts on 5/27/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AFHTTPClient.h"
#import "MALUserClient.h"
#import "UMALHTTPClient.h"

typedef void (^HTTPSuccessBlock)(id operation, id response);
typedef void (^HTTPFailureBlock)(id operation, NSError *error);

@interface MALHTTPClient : AFHTTPClient<NSXMLParserDelegate>

+ (MALHTTPClient *)sharedClient;

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;

- (void)getAnimeListForUser:(NSString *)user initialFetch:(BOOL)initialFetch success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)getAnimeDetailsForID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)addAnimeToListWithID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)updateDetailsForAnimeWithID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)searchForAnimeWithQuery:(NSString *)query success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;

- (void)getMangaListForUser:(NSString *)user initialFetch:(BOOL)initialFetch success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)getMangaDetailsForID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)addMangaToListWithID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)updateDetailsForMangaWithID:(NSNumber *)mangaID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
- (void)searchForMangaWithQuery:(NSString *)query success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;

- (void)getProfileForUser:(NSString *)user success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;


// Not yet implemented.
+ (void)getUserHistoryForUserID:(NSNumber *)userID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
+ (void)getUserAnimeHistoryForUserID:(NSNumber *)userID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
+ (void)getUserMangaHistoryForUserID:(NSNumber *)userID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;


+ (void)getTopRankingAnimeWithParams:(NSDictionary *)params success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
+ (void)getPopularRankingAnimeWithParams:(NSDictionary *)params success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;
+ (void)getUpcomingAnimeWithParams:(NSDictionary *)params success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;

+ (void)addAnimeToListWithID:(NSNumber *)animeID success:(HTTPSuccessBlock)success failure:(HTTPFailureBlock)failure;

@end
