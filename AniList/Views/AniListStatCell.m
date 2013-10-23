//
//  AniListStatCell.m
//  AniList
//
//  Created by Corey Roberts on 7/30/13.
//  Copyright (c) 2013 SpacePyro Inc. All rights reserved.
//

#import "AniListStatCell.h"
#import "Anime.h"
#import "Manga.h"

@implementation AniListStatCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *select = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 90)];
    select.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.1f];
    self.selectedBackgroundView = select;
}

+ (CGFloat)cellHeight {
    return 90;
}

- (void)setImageWithItem:(NSManagedObject *)object {
    Anime *anime;
    Manga *manga;
    
    NSURLRequest *imageRequest = nil;
    UIImage __block *cachedImage = nil;
    
    if([object isKindOfClass:[Anime class]]) {
        anime = (Anime *)object;
        imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:anime.image_url]];
        cachedImage = [[ImageManager sharedManager] imageForAnime:anime];
    }
    else {
        manga = (Manga *)object;
        imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:manga.image_url]];
        cachedImage = [[ImageManager sharedManager] imageForManga:manga];
    }
    
    // If the image hasn't been cached in memory, fetch from disk.
    if(!cachedImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // Fetch image from disk.
            if([object isKindOfClass:[Anime class]]) {
                cachedImage = [anime imageForAnime];
            }
            else {
                cachedImage = [manga imageForManga];
            }
            
            // If we don't have it stored on disk, fetch and save both to disk and in memory.
            if(!cachedImage) {
                [self.image setImageWithURLRequest:imageRequest placeholderImage:cachedImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.image.alpha = 0.0f;
                        self.image.image = image;
                        
                        [UIView animateWithDuration:0.3f animations:^{
                            self.image.alpha = 1.0f;
                        }];
                    });
                    
                    if([object isKindOfClass:[Anime class]]) {
                        if(!anime.image) {
                            // Save the image onto disk if it doesn't exist or they aren't the same.
                            [anime saveImage:image fromRequest:request];
                            [[ImageManager sharedManager] addImage:image forAnime:anime];
                        }
                    }
                    else {
                        if(!manga.image) {
                            // Save the image onto disk if it doesn't exist or they aren't the same.
                            [manga saveImage:image fromRequest:request];
                            [[ImageManager sharedManager] addImage:image forManga:manga];
                        }
                    }
                    
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    // Log failure.
                    ALLog(@"Couldn't fetch image at URL %@.", [request.URL absoluteString]);
                }];
            }
            else {
                if([object isKindOfClass:[Anime class]]) {
                    [[ImageManager sharedManager] addImage:cachedImage forAnime:anime];
                }
                else {
                    [[ImageManager sharedManager] addImage:cachedImage forManga:manga];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.image.image = cachedImage;
                });
            }
            
        });
    }
    else {
        self.image.image = cachedImage;
    }
}

#pragma mark - Text Methods

- (void)addShadow {
    [self.title addShadow];
    [self.progress addShadow];
    [self.type addShadow];
    [self.rank addShadow];
    [self.average_rank addShadow];
    [self.stat addShadow];
}

@end
