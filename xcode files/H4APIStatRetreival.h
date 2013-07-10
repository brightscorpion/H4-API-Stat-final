//
//  H4APIStatRetreival.h
//  h4API
//
//  Created by Charlie Pryor on 7/1/13.
//  Copyright (c) 2013 Charlie Pryor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol H4APIStatRetreivalDelegate;



@interface H4APIStatRetreival : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
//@property (nonatomic, assign) NSObject<H4APIStatRetreivalDelegate> *delegate;


-(void)loginAndReceiveAuthoTokens;

//Methods return a dictonary of the data that was requested
-(NSDictionary *)GetUserAchievements:(NSString *)gamertag;
-(NSDictionary *)GetOtherUserAchievements:(NSString *)gamertag;
-(NSDictionary *)GetPlaylists:(NSString *)gamertag;
-(NSDictionary *)GetGlobalChallenges:(NSString *)gamertag;
-(NSDictionary *)GetPlayerChallenges:(NSString *)gamertag;
-(NSDictionary *)GetGameMetadata:(NSString *)gamertag;
-(NSDictionary *)GetPlayerCard:(NSString *)gamertag;
-(NSDictionary *)GetMultiplePlayerCards:(NSString *)gamertag;
-(NSDictionary *)GetServiceRecord:(NSString *)gamertag;
-(NSDictionary *)GetGameHistory:(NSString *)gamertag;
-(NSDictionary *)GetGameDetails:(NSString *)gameID;
-(NSDictionary *)GetCommendations:(NSString *)gamertag;
-(NSDictionary *)GetRanks:(NSString *)gamertag;
-(NSDictionary *)GetCampaignDetails:(NSString *)gamertag;
-(NSDictionary *)GetSpartanOpsDetails:(NSString *)gamertag;
-(NSDictionary *)GetWarGameDetails:(NSString *)gamertag;
-(NSDictionary *)GetCustomGameDetails:(NSString *)gamertag;


-(void)didGetAutho;
-(void)FailedAutho;
-(void)receivingAuth;


-(void)addDelegate:(id<H4APIStatRetreivalDelegate>)delegate;
-(void)removeDelegate:(id<H4APIStatRetreivalDelegate>)delegate;

@end


@protocol H4APIStatRetreivalDelegate <NSObject>

@optional

-(void)didGetAuthoDel;
-(void)FailedAuthoDel;
-(void)receivingAuthDel;

@end