// ResolvWrapper.m
#import "ResolvWrapper.h"
#include <resolv.h>
#include <arpa/inet.h>
#include <netdb.h>

@implementation ResolvWrapper

+ (NSData *)lookupHostname:(NSString *)hostname {
    struct hostent *host = gethostbyname([hostname UTF8String]);
    if (host == NULL) {
        return nil;
    }

    NSMutableArray *addresses = [NSMutableArray array];
    for (int i = 0; host->h_addr_list[i] != NULL; i++) {
        NSString *ipAddress = [NSString stringWithUTF8String:inet_ntoa(*(struct in_addr *)host->h_addr_list[i])];
        [addresses addObject:ipAddress];
    }

    return [NSJSONSerialization dataWithJSONObject:addresses options:0 error:nil];
}

+ (NSMutableArray *)outPutDNSServers{
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);
    NSMutableArray *dnsArray = @[].mutableCopy;
    if( result == 0)
    {
        for (int i=0; i< res->nscount; i++) {
            NSString *s = [NSString stringWithUTF8String: inet_ntoa(res->nsaddr_list[i].sin_addr)];
            [dnsArray addObject:s];
        }
    }
    else{
        NSLog(@"%@",@" res_init result != 0");
    }
    
    res_nclose(res);
    
    return  dnsArray;
}

@end
