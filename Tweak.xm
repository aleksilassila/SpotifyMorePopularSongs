#import "Tweak.h"
#import <Cephei/HBPreferences.h>

HBPreferences *preferences;

NSString *bearerToken = nil;
int statusCode = nil;
NSDictionary *popularTracksData;

HUBComponentModelImplementation *moreSongsHeaderComponent;
NSMutableArray *extraPopularSongComponents = nil;

SPTPlayerState *playerState;

%group SpotifyMorePopularSongs

%subclass SpotifyMorePopularSongsAPI : NSObject

%new
// Fetch api token
+ (void)updateBearerToken {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *authorizationHeader = @"Basic NDJmODhmY2EzYjdjNDY5MmI2OWVkMDU0NmUwZDBkZjc6ZWFkZWY3ZDI4MDlhNGMzODg3MGYzMWE5ZjAxNGM5NjY=";
    
    NSString *ClientID = [preferences objectForKey:@"ClientID"];
    NSString *ClientSecret = [preferences objectForKey:@"ClientSecret"];
    
    if (ClientID.length && ClientSecret.length) {
        NSData *dataToEncode = [[NSString stringWithFormat:@"%@:%@", [preferences objectForKey:@"ClientID"], [preferences objectForKey:@"ClientSecret"]]
        dataUsingEncoding:NSUTF8StringEncoding];

        authorizationHeader = [dataToEncode base64EncodedStringWithOptions:0];
        authorizationHeader = [NSString stringWithFormat:@"Basic %@", authorizationHeader];
    }

    [request setHTTPMethod:@"POST"];
    [request addValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[@"grant_type=client_credentials" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    [request setURL:[NSURL URLWithString:@"https://accounts.spotify.com/api/token"]];

    NSHTTPURLResponse *responseCode = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:nil];

    if ([responseCode statusCode] == 200) {
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
        bearerToken = [responseDict objectForKey:@"access_token"];
    } else {
        bearerToken = nil;

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"More Popular Songs - Spotify API: Error %li", (long)[responseCode statusCode]] message:
            @"Looks like fetching Spotify API token failed. If there's an issue with my Spotify API project, you can create your own project at https://developer.spotify.com/dashboard/applications. It's easy. You can add your app credentials in settings."
            delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Close", nil];
        [alert show];
    }
}

%end

%hook SPTMainWindow
- (id)initWithTheme:(id)arg1 {    
    [%c(SpotifyMorePopularSongsAPI) updateBearerToken];

    return %orig;
}
%end

%hook SPTPlayerState
- (id)initWithDictionary:(id)arg1 {
    self = %orig;

    playerState = self;

    return self;
}
%end

%hook SPTFreeTierArtistViewController
- (id)initWithTheme:(id)arg1 pageIdentifier:(id)arg2 pageURI:(id)arg3 componentRegistry:(id)arg4 componentLayoutManager:(id)arg5 imageLoaderFactory:(id)arg6 commandHandler:(id)arg7 viewModelProvider:(id)arg8 impressionLogger:(id)arg9 loadingLogger:(id)arg10 ubiLogger:(id)arg11 feedbackButtonViewModel:(id)arg12 contextMenuButtonViewModel:(id)arg13 navigationItemDecorator:(id)arg14 shareDragDelegateFactory:(id)arg15 {
    if (bearerToken != nil)
    {
        // Fetch playlist data

        extraPopularSongComponents = nil;
        statusCode = nil;
        popularTracksData = nil;

        bool fetchAgain = true;
        while (fetchAgain) {
            NSArray *components = [[arg3 absoluteString] componentsSeparatedByString:@":"];
            NSString *artistId = components[2];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setHTTPMethod:@"GET"];
            [request addValue:[NSString stringWithFormat:@"Bearer %@", bearerToken] forHTTPHeaderField:@"Authorization"];
            [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/artists/%@/top-tracks?country=FI", artistId]]];

            NSHTTPURLResponse *responseCode = nil;
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:nil];

            statusCode = [responseCode statusCode];

            if (statusCode == 429) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"More Popular Songs - Spotify API: Error %li", (long)[responseCode statusCode]] message:
                    @"Looks like there's too many requests to Spotify API. You have to wait before using api, or you can create your own project at https://developer.spotify.com/dashboard/applications. It's easy. You can add your app credentials in settings."
                delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Close", nil];
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
%end

// Inject generated components to UICollectionView
%hook HUBCollectionViewDataSource
-(void)setComponentModels:(NSArray *)arg1 {
    if ([arg1 count] != 0 && [extraPopularSongComponents count] != 0)
    {
        HUBComponentModelImplementation *component = arg1[0];

        bool isArtistPageDataSource = false;

        for (HUBComponentModelImplementation *component in arg1) {
            if ([component.identifier isEqualToString:@"artist-entity-view-top-tracks-combined"]) {
                isArtistPageDataSource = true;
                break;
            }
        }

        if (isArtistPageDataSource) {
            NSMutableArray *newArray = [arg1 mutableCopy];

            for (int i = 0; i < [arg1 count]; i++) {
                component = arg1[i];
                if ([component.identifier isEqualToString:@"artist-entity-view-releases_link"]) {
                    for (int s = 0; s < [extraPopularSongComponents count]; s++) {
                        [newArray insertObject:extraPopularSongComponents[s] atIndex:i+s+1];
                    }

                    [newArray insertObject:moreSongsHeaderComponent atIndex:i+1];
                }
            }

            %orig(newArray);
            return;
        }

    }
    %orig;

}
%end

%hook HUBComponentModelImplementation
- (id)initWithIdentifier:(id)arg1 type:(unsigned long long)arg2 index:(unsigned long long)arg3 groupIdentifier:(id)arg4 componentIdentifier:(id)arg5 componentCategory:(id)arg6 title:(id)arg7 subtitle:(id)arg8 accessoryTitle:(id)arg9 descriptionText:(id)arg10 mainImageData:(id)arg11 backgroundImageData:(id)arg12 customImageData:(id)arg13 icon:(id)arg14 target:(id)arg15 events:(id)arg16 metadata:(id)arg17 loggingData:(id)arg18 customData:(id)arg19 parent:(id)arg20 {
    if (statusCode == 200)
    {
        if ([arg1 isEqualToString:@"artist-entity-view-top-tracks-combined"]) {
            moreSongsHeaderComponent = [[%c(HUBComponentModelImplementation) alloc] 
            initWithIdentifier:@"artist-entity-view-top-tracks-combined-more" type:arg2 index:arg3 groupIdentifier:arg4 componentIdentifier:arg5 componentCategory:arg6 title:@"More popular songs" subtitle:arg8 accessoryTitle:arg9 descriptionText:arg10 mainImageData:arg11 backgroundImageData:arg12 customImageData:arg13 icon:arg14 target:arg15 events:arg16 metadata:arg17 loggingData:arg18 customData:arg19 parent:arg20];

        } else if ([arg1 isEqualToString:@"artist-entity-view-top-tracks-combined_row4"]) {
            NSMutableArray *contextTracks = [NSMutableArray new];

            for (int i = 0; i < [[popularTracksData objectForKey:@"tracks"] count]; i++) {
                [contextTracks addObject:@{ @"uri": [[popularTracksData objectForKey:@"tracks"][i] objectForKey:@"uri"] }];
            }

            extraPopularSongComponents = [NSMutableArray new];

            // Generate extra tracks
            for (int i = 5; i < [[popularTracksData objectForKey:@"tracks"] count]; i++) {
                NSDictionary *track = [popularTracksData objectForKey:@"tracks"][i];
                NSString *currentTrackUri = [track objectForKey:@"uri"];

                NSDictionary *events = @{
                    @"click": [[%c(HUBCommandModelImplementation) alloc] initWithName:@"playFromContext" data:@{
                        @"uri" : currentTrackUri,
                        @"player": @{
                            @"context": @{
                                @"pages": @[
                                    @{
                                        @"tracks": contextTracks
                                    },
                                    @{
                                        @"page_url": [NSString stringWithFormat:@"hm://artistplaycontext/v1/page/spotify/artist-top-tracks-extensions/%@?exclude_uri=spotify:track:1sgDyuLooyvEML4oHspNza,spotify:track:1kKYjjfNYxE0YYgLa7vgVY,spotify:track:3Be7CLdHZpyzsVijme39cW,spotify:track:4dyrqiXUcK29hzrL2elqO3,spotify:track:2nx0EIlIKMnMgWnj40O0HQ", currentTrackUri]
                                    }
                                ],
                                @"uri": [[track objectForKey:@"artists"][0] objectForKey:@"uri"]
                            },
                            @"options": @{
                                @"skip_to": @{
                                    @"page_index": @0,
                                    @"track_uri": currentTrackUri
                                }
                            }
                        }
                    }],
                    @"rightAccessoryClick": [[%c(HUBCommandModelImplementation) alloc] initWithName:@"contextMenu" data:@{ @"uri": currentTrackUri}]
                };

                NSDictionary *metadata = @{
                    @"playing": [currentTrackUri isEqualToString:[playerState.track.URI absoluteString]] ? @1 : @0,
                    @"album_uri": [[track objectForKey:@"album"] objectForKey:@"uri"],
                    @"uri": currentTrackUri
                };

                // NSDictionary *loggingData = @{
                //     @"interaction:item_id": @"artist-entity-view-top-tracks-combined_1",
                //     @"ubi:app": @"music",
                //     @"ubi:generator_commit": @"78f951fdd7ee8835012e762340d109995351b2c0",
                //     @"ubi:impression": @1,
                //     @"ubi:path": @[
                //         @{
                //             @"name": @"top_tracks"
                //         },
                //         @{
                //             @"name": @"track_row",
                //             @"position": @(5 + [extraPopularSongComponents count]),
                //             @"uri": currentTrackUri
                //         }
                //     ],
                //     @"ubi:specification_commit": @"07792a58628e63c39e81f97525e26653aeb06538",
                //     @"ubi:specification_id": @"mobile-artist-page",
                //     @"ubi:specification_version": @"16.0.0",
                //     @"ui:group": @"artist-entity-view-top-tracks-combined",
                //     @"ui:index_in_block": @(5 + [extraPopularSongComponents count]),
                //     @"ui:source": @"05abfc9b00be1b-a175a1-0586-0001-db0a8c0c"
                // };

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
                    @"rowNumber": @(i - 4)
                };

                [extraPopularSongComponents addObject:
                    [[%c(HUBComponentModelImplementation) alloc] 
                    initWithIdentifier:[NSString stringWithFormat:@"artist-entity-view-top-tracks-combined_row%i", i] type:arg2 index:arg3 groupIdentifier:arg4 componentIdentifier:arg5 componentCategory:arg6 title:[track objectForKey:@"name"] subtitle:[[track objectForKey:@"album"] objectForKey:@"name"] accessoryTitle:arg9 descriptionText:arg10 mainImageData:[
                        [%c(HUBComponentImageDataImplementation) alloc]
                        initWithIdentifier:nil type:0 URL:[NSURL URLWithString:[[[track objectForKey:@"album"] objectForKey:@"images"][2] objectForKey:@"url"]] placeholderIcon:nil localImage:nil customData:@{}
                    ] backgroundImageData:arg12 customImageData:arg13 icon:arg14 target:arg15 events:events metadata:metadata loggingData:arg18 customData:customData parent:arg20]
                ];
            }
        }
    }

    return %orig;
}

%end

%end

%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"me.aleksilassila.spotifymorepopularsongsprefs"];
    [preferences registerDefaults:@{
        @"Enabled": @YES,
        @"ClientID": @"",
        @"ClientSecret": @""
    }];

    if ([preferences boolForKey:@"Enabled"] == 1) {
        %init(SpotifyMorePopularSongs);
    }
}