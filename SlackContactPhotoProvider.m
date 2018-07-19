#import "SlackContactPhotoProvider.h"

@implementation SlackContactPhotoProvider

  - (DDNotificationContactPhotoPromiseOffer *)contactPhotoPromiseOfferForNotification:(DDUserNotification *)notification {
    NSString *user_id;
    NSString *avatar_url;

    NSString *token = @"";
    NSString *slack_url = [notification.applicationUserInfo valueForKeyPath:@"url"];
    NSString *slack_id = [self valueForKey:@"id" fromQueryItems:[[NSURLComponents alloc] initWithString:slack_url].queryItems];
    NSString *message_type = [slack_id substringToIndex:1];

    NSURL *im_history_url = [NSURL URLWithString:@"https://slack.com/api/im.history"];
    NSURL *channels_info_url = [NSURL URLWithString:@"https://slack.com/api/channels.info"];
    NSURL *users_profile_get_url = [NSURL URLWithString:@"https://slack.com/api/users.profile.get"];

    NSString *user_id_params = [NSString stringWithFormat:@"token=%@&channel=%@", token, slack_id];

    if ([message_type isEqualToString:@"D"]){
      NSMutableDictionary *json = [self makeApiCall:im_history_url params:user_id_params];
      user_id = json[@"messages"][0][@"user"];
    } else if([message_type isEqualToString:@"C"]){
      NSMutableDictionary *json = [self makeApiCall:channels_info_url params:user_id_params];
      user_id = json[@"channel"][@"latest"][@"user"];
    }

    NSString *avatar_url_params = [NSString stringWithFormat:@"token=%@&user=%@", token, user_id];
    NSMutableDictionary *user_json = [self makeApiCall:users_profile_get_url params:avatar_url_params];
    avatar_url = user_json[@"profile"][@"image_192"];

    return [NSClassFromString(@"DDNotificationContactPhotoPromiseOffer") offerDownloadingPromiseWithPhotoIdentifier:avatar_url fromURL:[NSURL URLWithString:avatar_url]];
  }

  - (NSString *)valueForKey:(NSString *)key fromQueryItems:(NSArray *)queryItems {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate]firstObject];
    return queryItem.value;
  }

  -(NSMutableDictionary *)makeApiCall:(NSURL *)url params:(NSString *)params {
    NSError *error;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];

    return json;
  }

@end
