#import <sqlite3.h>
#import "FolderFinder.h"
#import "SlackContactPhotoProvider.h"

@implementation SlackContactPhotoProvider
  - (DDNotificationContactPhotoPromiseOffer *)contactPhotoPromiseOfferForNotification:(DDUserNotification *)notification {
    NSDictionary *alert = [notification applicationUserInfo];
    NSString *body = alert[@"aps"][@"alert"][@"body"];
    NSString *threadId = alert[@"aps"][@"thread-id"];
    NSString *messageType = [threadId substringToIndex:1];
    NSString *teamId = [notification.applicationUserInfo valueForKeyPath:@"team_id"];
    NSString *username;

    if ([messageType isEqualToString:@"D"]){
      username = [body componentsSeparatedByString:@":"][0];
    } else if([messageType isEqualToString:@"C"]){
      username = [body componentsSeparatedByString:@":"][0];
      username = [body componentsSeparatedByString:@" "][1];
    }

    username = [username stringByReplacingOccurrencesOfString:@":" withString:@""];
    username = [username stringByReplacingOccurrencesOfString:@"@" withString:@""];

    NSString *containerPath = [FolderFinder findDataFolder:@"com.tinyspeck.chatlyio"];
    NSString *databasePath = [NSString stringWithFormat:@"%@/Library/Application Support/Slack/%@/Database/main_db", containerPath, teamId];

    const char *dbpath = [databasePath UTF8String];
    sqlite3 *_slackdb;

    if (sqlite3_open(dbpath, &_slackdb) == SQLITE_OK) {
      const char *stmt = [[NSString stringWithFormat:@"SELECT 'https://ca.slack-edge.com/' || ZTEAMID || '-' || ZTSID ||  '-' || ZAVATARHASH || '-512' as url FROM ZSLKCOREDATAUSER WHERE ZNAME = '%@';", username] UTF8String];
      sqlite3_stmt *statement;

      if (sqlite3_prepare_v2(_slackdb, stmt, -1, &statement, NULL) == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
          const unsigned char *result = sqlite3_column_text(statement, 0);
          NSString *imageURLStr = [NSString stringWithUTF8String:(char *)result];
          NSURL *imageURL = [NSURL URLWithString:imageURLStr];

          return [NSClassFromString(@"DDNotificationContactPhotoPromiseOffer") offerDownloadingPromiseWithPhotoIdentifier:imageURLStr fromURL:imageURL];
        }
        sqlite3_finalize(statement);
      }
      sqlite3_close(_slackdb);
    }

    return nil;
  }
@end
