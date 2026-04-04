// ResolvWrapper.h
#import <Foundation/Foundation.h>

@interface ResolvWrapper : NSObject

+ (NSData *)lookupHostname:(NSString *)hostname;

+ (NSMutableArray *)outPutDNSServers;

@end
