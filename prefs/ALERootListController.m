#include "ALERootListController.h"

@implementation ALERootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (void)openGithub {
    [[UIApplication sharedApplication]
    openURL:[NSURL URLWithString:@"https://github.com/aleksilassila/SpotifyMorePopularSongs"]
    options:@{}
    completionHandler:nil];
}

- (void)openHomepage {
    [[UIApplication sharedApplication]
    openURL:[NSURL URLWithString:@"http://aleksilassila.me"]
    options:@{}
    completionHandler:nil];
}

- (void)buyMeACoffee {
    [[UIApplication sharedApplication]
    openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=aleksi.emil.lassila%40gmail.com&item_name=Support+my+work+%3C3&currency_code=EUR&source=url"]
    options:@{}
    completionHandler:nil];
}

@end
