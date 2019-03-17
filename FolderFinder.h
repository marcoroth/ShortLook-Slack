@interface FolderFinder : NSObject
  +(NSString*) findDataFolder:(NSString*) appName;
  +(NSString*) findFolder:(NSString*) appName folder:(NSString*) dir;
@end
