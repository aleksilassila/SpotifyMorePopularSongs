#import "Tweak.h"

NSString *bearerToken = nil;

NSMutableArray *extraPopularSongs = nil;

int statusCode = nil;

NSDictionary *popularTracksData;
NSArray *artistId;

%subclass SpotifyMorePopularSongsAPI : NSObject

%new
+ (void)updateBearerToken {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"Basic NDJmODhmY2EzYjdjNDY5MmI2OWVkMDU0NmUwZDBkZjc6ZWFkZWY3ZDI4MDlhNGMzODg3MGYzMWE5ZjAxNGM5NjY=" forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[@"grant_type=client_credentials" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    [request setURL:[NSURL URLWithString:@"https://accounts.spotify.com/api/token"]];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error) {
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            bearerToken = [responseDict objectForKey:@"access_token"];
            NSLog(@"Logged set bearer: %@", bearerToken);
        } else {
            NSLog(@"Logged error setting bearer");
            bearerToken = nil;
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SpotifyMorePopularSongs API" message:
                @"Looks like fetching Spotify API token failed. If there's an issue with my Spotify API project, you can create your own project at https://developer.spotify.com/dashboard/applications. It's easy. After that add your app credentials to settings."
            delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
            [alert show];
        }
    }];
}

%end

%hook SPTMainWindow
- (id)initWithTheme:(id)arg1 {    
    [%c(SpotifyMorePopularSongsAPI) updateBearerToken];

    return %orig;
}
%end

// HTTP Shit
%hook SPTFreeTierArtistViewController
- (id)initWithTheme:(id)arg1 pageIdentifier:(id)arg2 pageURI:(id)arg3 componentRegistry:(id)arg4 componentLayoutManager:(id)arg5 imageLoaderFactory:(id)arg6 commandHandler:(id)arg7 viewModelProvider:(id)arg8 impressionLogger:(id)arg9 loadingLogger:(id)arg10 ubiLogger:(id)arg11 feedbackButtonViewModel:(id)arg12 contextMenuButtonViewModel:(id)arg13 navigationItemDecorator:(id)arg14 shareDragDelegateFactory:(id)arg15 {
    if (bearerToken != nil)
    {
        bool fetchAgain = true;
        while (fetchAgain) {

            NSArray *components = [[arg3 absoluteString] componentsSeparatedByString:@":"];
            artistId = components[2];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setHTTPMethod:@"GET"];
            [request addValue:[NSString stringWithFormat:@"Bearer %@", bearerToken] forHTTPHeaderField:@"Authorization"];
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/artists/%@/top-tracks?country=FI", artistId]]];

            NSHTTPURLResponse *responseCode = nil;
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:nil];

            statusCode = [responseCode statusCode];

            if (statusCode == 429) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SpotifyMorePopularSongs API" message:
                    @"Looks there's too many requests to Spotify API. You have to wait before using api, or you can create your own project at https://developer.spotify.com/dashboard/applications. It's easy. After that add your app credentials to settings and your tweak should work again."
                delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
                [alert show];
                fetchAgain = false;
                continue;
            } else if (statusCode == 401) {
                [%c(SpotifyMorePopularSongsAPI) updateBearerToken];
                continue;
            }

            popularTracksData = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
            fetchAgain = false;

        }
    }
    
    return %orig;
}

- (void)viewWillDisappear:(_Bool)arg1 {
    extraPopularSongs = nil;
    statusCode = nil;

    popularTracksData = nil;
    artistId = nil;

    return %orig;
}
%end

%hook HUBCollectionViewDataSource
- (long long)numberOfSectionsInCollectionView:(id)arg1 {
    if ([self.componentModels count] != 0 && extraPopularSongs != nil) {

        HUBComponentModelImplementation *component = self.componentModels[0];
        if ([component.identifier isEqualToString:@"artist-entity-view-liked-tracks-row"] || [component.identifier isEqualToString:@"artist-entity-view-top-tracks-combined"]) {
            NSMutableArray *newArray = [self.componentModels mutableCopy];

            int index = [component.identifier isEqualToString:@"artist-entity-view-liked-tracks-row"] ? 7 : 6;
            int i;
            for (i = 0; i < [extraPopularSongs count]; i++) {
                NSLog(@"Logged inserting tracks...");
                [newArray insertObject:extraPopularSongs[i] atIndex:index+i];
            }

            self.componentModels = newArray;
        }

    }

    return %orig;
}
%end

%hook HUBComponentModelImplementation

- (id)initWithIdentifier:(id)arg1 type:(unsigned long long)arg2 index:(unsigned long long)arg3 groupIdentifier:(id)arg4 componentIdentifier:(id)arg5 componentCategory:(id)arg6 title:(id)arg7 subtitle:(id)arg8 accessoryTitle:(id)arg9 descriptionText:(id)arg10 mainImageData:(id)arg11 backgroundImageData:(id)arg12 customImageData:(id)arg13 icon:(id)arg14 target:(id)arg15 events:(id)arg16 metadata:(id)arg17 loggingData:(id)arg18 customData:(id)arg19 parent:(id)arg20 {
    if (statusCode == 200 && [arg1 isEqualToString:@"artist-entity-view-top-tracks-combined_row4"]) {
        NSMutableArray *contextTracks = [NSMutableArray new];

        int i;
        for (i = 0; i < [[popularTracksData objectForKey:@"tracks"] count]; i++) {
            [contextTracks addObject:@{ @"uri": [[popularTracksData objectForKey:@"tracks"][i] objectForKey:@"uri"] }];
        }

        extraPopularSongs = [NSMutableArray new];

        // Generate extra tracks
        NSLog(@"Logged generating tracks...");
        for (i = 5; i < [[popularTracksData objectForKey:@"tracks"] count]; i++) {
            NSDictionary *track = [popularTracksData objectForKey:@"tracks"][i];
            NSString *currentTrackUri = [track objectForKey:@"uri"];

            NSDictionary *events = @{
                @"click": [[%c(HUBCommandModelImplementation) alloc] initWithName:@"playFromContext" data:@{
                    @"uri" : currentTrackUri,
                    @"player" : @{
                        @"context" : @{
                            @"pages" : @[
                                @{
                                    @"tracks" : contextTracks
                                },
                                @{
                                    @"page_url" : [NSString stringWithFormat:@"hm://artistplaycontext/v1/page/spotify/artist-top-tracks-extensions/%@?exclude_uri=spotify:track:1sgDyuLooyvEML4oHspNza,spotify:track:1kKYjjfNYxE0YYgLa7vgVY,spotify:track:3Be7CLdHZpyzsVijme39cW,spotify:track:4dyrqiXUcK29hzrL2elqO3,spotify:track:2nx0EIlIKMnMgWnj40O0HQ", currentTrackUri]
                                }
                            ],
                            @"uri" : [NSString stringWithFormat:@"spotify:artist:%@", artistId]
                        },
                        @"options" : @{
                            @"skip_to" : @{
                                @"page_index" : @0,
                                @"track_uri" : currentTrackUri
                            }
                        }
                    }
                }],
                @"rightAccessoryClick": [[%c(HUBCommandModelImplementation) alloc] initWithName:@"contextMenu" data:@{ @"uri": currentTrackUri}]
            };

            NSDictionary *metadata = @{
                @"album_uri": [[track objectForKey:@"album"] objectForKey:@"uri"],
                @"preview_id": [[[track objectForKey:@"preview_url"] componentsSeparatedByString:@"mp3-preview/"][1] componentsSeparatedByString:@"?"][0],
                @"uri": currentTrackUri
            };

            NSDictionary *loggingData = @{
                @"interaction:item_id": @"artist-entity-view-top-tracks-combined_4",
                @"ubi:app": @"music",
                @"ubi:generator_commit": @"78f951fdd7ee8835012e762340d109995351b2c0",
                @"ubi:impression": @1,
                @"ubi:path": @[
                    @{
                        @"name": @"top_tracks"
                    },
                    @{
                        @"name": @"track_row",
                        @"position": @(5 + [extraPopularSongs count]),
                        @"uri": currentTrackUri
                    }
                ],
                @"ubi:specification_commit": @"07792a58628e63c39e81f97525e26653aeb06538",
                @"ubi:specification_id": @"mobile-artist-page",
                @"ubi:specification_version": @"16.0.0",
                @"ui:group": @"artist-entity-view-top-tracks-combined",
                @"ui:index_in_block": @(5 + [extraPopularSongs count]),
                @"ui:source": @"05abfc9b00be1b-a175a1-0586-0001-db0a8c0c"
            };

            NSDictionary *customData =  @{
                @"accessibility": @{
                    @"accessoryRight": @{
                        @"label": @"Context menu"
                    }
                },
                @"accessoryRightIcon": @"more",
                @"artists": @[
                    @{
                        @"name": [[track objectForKey:@"artists"][0] objectForKey:@"name"],
                        @"uri": [[track objectForKey:@"artists"][0] objectForKey:@"uri"]
                    }
                ],
                @"disabled": @0,
                @"glue:subtitleStyle": @"metadata",
                @"rowNumber": @(6 + [extraPopularSongs count])
            };

            [extraPopularSongs addObject:
                [[%c(HUBComponentModelImplementation) alloc] 
                initWithIdentifier:@"artist-entity-view-top-tracks-combined_row0" type:arg2 index:arg3 groupIdentifier:arg4 componentIdentifier:arg5 componentCategory:arg6 title:[track objectForKey:@"name"] subtitle:@"Extra Item" accessoryTitle:arg9 descriptionText:arg10 mainImageData:[
                    [%c(HUBComponentImageDataImplementation) alloc]
                    initWithIdentifier:nil type:0 URL:[NSURL URLWithString:[[[track objectForKey:@"album"] objectForKey:@"images"][2] objectForKey:@"url"]] placeholderIcon:nil localImage:nil customData:@{}
                ] backgroundImageData:arg12 customImageData:arg13 icon:arg14 target:arg15 events:events metadata:metadata loggingData:loggingData customData:customData parent:arg20]
            ];
        }
    }
    // NSLog(@"Logged arg1: %@", arg1);
    // NSLog(@"Logged arg2: %llu", arg2);
    // NSLog(@"Logged arg3: %llu", arg3);
    // NSLog(@"Logged arg4: %@", arg4);
    // NSLog(@"Logged arg5: %@", arg5);
    // NSLog(@"Logged arg6: %@", arg6);
    // NSLog(@"Logged arg7: %@", arg7);
    // NSLog(@"Logged arg8: %@", arg8);
    // NSLog(@"Logged arg9: %@", arg9);
    // NSLog(@"Logged arg10: %@", arg10);
    // NSLog(@"Logged arg11: %@", arg11);
    // NSLog(@"Logged arg12: %@", arg12);
    // NSLog(@"Logged arg13: %@", arg13);
    // NSLog(@"Logged arg14: %@", arg14);
    // NSLog(@"Logged arg15: %@", arg15);
    // NSLog(@"Logged arg16: %@", arg16);
    // NSLog(@"Logged arg17: %@", arg17);
    // NSLog(@"Logged arg18: %@", arg18);
    // NSLog(@"Logged arg19: %@", arg19);
    // NSLog(@"Logged arg20: %@", arg20);

    return %orig;
}

%end
