@interface HUBCollectionViewDataSource : NSObject
@property(copy, nonatomic) NSArray *componentModels;
@end

@interface HUBComponentModelImplementation : NSObject
@property(readonly, copy, nonatomic) NSString *identifier;
- (id)initWithIdentifier:(id)arg1 type:(unsigned long long)arg2 index:(unsigned long long)arg3 groupIdentifier:(id)arg4 componentIdentifier:(id)arg5 componentCategory:(id)arg6 title:(id)arg7 subtitle:(id)arg8 accessoryTitle:(id)arg9 descriptionText:(id)arg10 mainImageData:(id)arg11 backgroundImageData:(id)arg12 customImageData:(id)arg13 icon:(id)arg14 target:(id)arg15 events:(id)arg16 metadata:(id)arg17 loggingData:(id)arg18 customData:(id)arg19 parent:(id)arg20;
@end

@interface HUBCommandModelImplementation : NSObject
- (id)initWithName:(id)arg1 data:(id)arg2;
@property(readonly, copy, nonatomic) NSString *name;
@end

@interface HUBComponentImageDataImplementation : NSObject
- (id)initWithIdentifier:(id)arg1 type:(long long)arg2 URL:(id)arg3 placeholderIcon:(id)arg4 localImage:(id)arg5 customData:(id)arg6;
@end

@interface SpotifyMorePopularSongsAPI
+ (void)updateBearerToken;
@end

@interface SPTPlayerTrack : NSObject
@property(copy, nonatomic) NSURL *URI;
@end


@interface SPTPlayerState : NSObject
@property(retain, nonatomic) SPTPlayerTrack *track;
@end


@interface SPTNowPlayingEntityDecorationController : NSObject
@property(retain, nonatomic) SPTPlayerState *playerState;
@end
