//
//  H4APIStatRetreival.m
//  h4API
//
//  Created by Charlie Pryor on 7/1/13.
//  Copyright (c) 2013 Charlie Pryor. All rights reserved.
//
//https://settings.svc.halowaypoint.com/RegisterClientService.svc/register/webapp/AE5D20DCFA0347B1BCE0A5253D116752

#import "H4APIStatRetreival.h"
@interface H4APIStatRetreival ()
@property (nonatomic) NSMutableData *data;
@property (nonatomic) NSString *cookie;
@property (nonatomic) NSString *spartanToken;
@property (nonatomic) BOOL hasSpartanToken;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) NSTimer *timer;

@property (nonatomic)NSMutableArray *dellegates;
@end

@implementation H4APIStatRetreival


-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    //NSLog(@"response");
    [self.data setLength:0];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //NSLog(@"finished");
    NSString *connectionString = [[NSString alloc] initWithData:_data encoding:NSASCIIStringEncoding];
    //NSLog(@"%@",connectionString);
    
    NSScanner *scannerOfZeWebData = [NSScanner scannerWithString:connectionString];
    NSString *SpartanToken;
    NSString *gamerTag;
    NSString *AnalyticsToken;
    [scannerOfZeWebData scanUpToString:@"\"SpartanToken\":\"" intoString:nil];
    [scannerOfZeWebData scanString:@"\"SpartanToken\":\"" intoString:nil];
    [scannerOfZeWebData scanUpToString:@"\"" intoString:&SpartanToken];
    //NSLog(@"SPARTANTOKEN:    %@",SpartanToken);
    _spartanToken = SpartanToken;
    [scannerOfZeWebData scanUpToString:@"\"Gamertag\":\"" intoString:nil];
    [scannerOfZeWebData scanString:@"\"Gamertag\":\"" intoString:nil];
    [scannerOfZeWebData scanUpToString:@"\"" intoString:&gamerTag];
    //NSLog(@"GAMERTAG:   %@",gamerTag);
    [scannerOfZeWebData scanUpToString:@"\"AnalyticsToken\":\"" intoString:nil];
    [scannerOfZeWebData scanString:@"\"AnalyticsToken\":\"" intoString:nil];
    [scannerOfZeWebData scanUpToString:@"\"" intoString:&AnalyticsToken];
    //NSLog(@"ANALITICKSTOKEN:   %@",AnalyticsToken);
    
    //NSLog(@"FINISHED");
    _timer = [NSTimer scheduledTimerWithTimeInterval:3000 target:self selector:@selector(loginAndReceiveAuthoTokens) userInfo:nil repeats:NO];
    if (AnalyticsToken != nil && gamerTag != nil && SpartanToken != nil) {
        //NSLog(@"sucess");
        _hasSpartanToken = YES;
        [self didGetAutho];
    } else {
        //NSLog(@"process failed");
        [self FailedAutho];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //NSLog(@"data");
    [_data appendData:data];
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //NSLog(@"failed");
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    //NSLog(@"challenged");
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(NSMutableData *)data {
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    return _data;
}
-(NSOperationQueue *)queue{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}


-(void)loginAndReceiveAuthoTokens {
    NSLog(@"login and receive auth token");
    _hasSpartanToken = NO;
    NSString *userAgent = @"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11";
    NSString *URLlogin = @"https://login.live.com/oauth20_authorize.srf?client_id=000000004C0BD2F1&scope=xbox.basic%20xbox.offline_access&response_type=code&redirect_uri=https://app.halowaypoint.com/oauth/callback&state=MAdodHRwczovL2FwcC5oYWxvd2F5cG9pbnQuY29tL2VuLXVzLw&display=touch";
    
    NSString *urlHalo = @"https://app.halowaypoint.com/en-us/";
    
    
    NSURL *url = [NSURL URLWithString:URLlogin];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:10];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:urlHalo forHTTPHeaderField:@"Referer"];
    
    //NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
    //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response,NSData *data, NSError *error)
     {
         
         if ([data length] >0 && error == nil)
         {
             NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
             NSDictionary *fields = [HTTPResponse allHeaderFields];
             //NSLog(@"%@",fields);
             _cookie = [fields valueForKey:@"Set-Cookie"];
             
             NSString *connectionString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
             NSString *cRegexLoginPPFT = @"var\\s+ServerData\\s*=\\s*[^<]+(<input(\\s+[a-zA-Z0-9]+\\s*=\\s*(\"[^\"]*\"|[^ ]+))*\\s*/?\\s*>)";
             NSError *RegexError;
             NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:cRegexLoginPPFT options:0 error:&RegexError];
             NSTextCheckingResult *match = [regex firstMatchInString:connectionString options:0 range:NSMakeRange(0, [connectionString length])];
             NSString *ppftValue;
             if (!RegexError) {
                 
                 ppftValue = [connectionString substringWithRange:[match rangeAtIndex:2]];
                 
                 
                 
                 
                 /***********************************************************
                  start of secondConnection
                  **********************************************************/
                 
                 
                 
                 NSString *ppftRealDeal;
                 NSError *error;
                 NSString *cRegexLoginPPFTValue = @"value=\"([^\"]+)\"";
                 
                 NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:cRegexLoginPPFTValue options:0 error:&error];
                 NSTextCheckingResult *match = [regex firstMatchInString:connectionString options:0 range:NSMakeRange(0, [connectionString length])];
                 
                 ppftRealDeal = [connectionString substringWithRange:[match rangeAtIndex:1]];
                 
                 
                 NSString *postLogin = @"https://login.live.com/ppsecure/post.srf?client_id=000000004C0BD2F1&scope=xbox.basic%20xbox.offline_access&response_type=code&redirect_uri=https://app.halowaypoint.com/oauth/callback&state=MAdodHRwczovL2FwcC5oYWxvd2F5cG9pbnQuY29tL2VuLXVzLw&display=touch&bk=";
                 NSString *userAgent = @"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11";
                 NSString *URLlogin = @"https://login.live.com/oauth20_authorize.srf?client_id=000000004C0BD2F1&scope=xbox.basic%20xbox.offline_access&response_type=code&redirect_uri=https://app.halowaypoint.com/oauth/callback&state=MAdodHRwczovL2FwcC5oYWxvd2F5cG9pbnQuY29tL2VuLXVzLw&display=touch";
                 
                 
                 NSString *email = @"email";
                 #error Please replace the email and password with valid xbox live credentials that are attached to a gamertag
                 NSString *pasword = @"password";
                 NSString *loginPPSX = @"var\\s+ServerData\\s*=\\s*[^<]+F\\s*:\\s*['\"]([a-zA-Z0-9]*)['\"]";
                 NSString *ppft = [NSString stringWithFormat:@"PPFT=%@&login=%@&passwd=%@&LoginOptions=%@&NewUser=%@&PPSX=%@&type=%@&i3=%@&m1=%@&m2=%@&m3=%@&i12=%@&i17=%@&i18=%@",ppftRealDeal,email,pasword,@"3",@"1",loginPPSX,@"11",@"15842",@"1920",@"1080",@"0",@"1",@"0",@"__MobileLogin|1,"];
                 NSData *ppftData = [ppft dataUsingEncoding:NSASCIIStringEncoding];
                 //
                 NSString *ASCIData = [NSString stringWithFormat:@"%@",ppftData];
                 NSString *dataLength = [NSString stringWithFormat:@"%i",[ASCIData length]];
                 
                 
                 NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:postLogin]];//normally post login
                 [request2 setHTTPMethod:@"Post"];
                 [request2 setHTTPBody:ppftData];
                 [request2 setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                 [request2 setValue:userAgent forHTTPHeaderField:@"User-Agent"];
                 [request2 setValue:URLlogin forHTTPHeaderField:@"Referer"];
                 [request2 setValue:dataLength forHTTPHeaderField:@"Content-Length"];
                 [request2 setValue:_cookie forHTTPHeaderField:@"Set-Cookie"];
                 
                 [NSURLConnection
                  sendAsynchronousRequest:request2
                  queue:_queue
                  completionHandler:^(NSURLResponse *response2,
                                      NSData *data2,
                                      NSError *error2)
                  {
                      
                      if ([data2 length] >0 && error2 == nil)
                      {
                          
                          NSString *connectionString = [[NSString alloc] initWithData:data2 encoding:NSASCIIStringEncoding];
                          
                          dispatch_async(dispatch_get_main_queue(), ^(void){
                              
                              
                              [self receiveSpartanToken:connectionString];
                          });
                          
                      }
                      else if ([data2 length] == 0 && error2 == nil)
                      {
                          //NSLog(@"Nothing was downloaded.");
                      }
                      else if (error2 != nil){
                          //NSLog(@"Error = %@", error2.localizedDescription);
                      }
                      
                  }];
                 
                 
                 
                 
                 
                 
             }
             
         }
         else if ([data length] == 0 && error == nil)
         {
             //NSLog(@"Nothing was downloaded.");
         }
         else if (error != nil){
             NSLog(@"Error = %@", error.localizedDescription);
         }
         
     }];
    
    
}

-(void)receiveSpartanToken:(NSString *)webData {
    NSLog(@"Receive spartan token");
    //NSLog(@"%@",webData);
    
    //NSLog(@"hit");
    
    NSScanner *webDataScan = [NSScanner scannerWithString:webData];
    NSString *accessToken;
    NSString *AuthenticationToken;
    NSString *expiresIn;
    [webDataScan scanUpToString:@"access_token:'" intoString:nil];
    [webDataScan scanString:@"access_token:'" intoString:nil];
    [webDataScan scanUpToString:@"'" intoString:&accessToken];
    NSLog(@"ACCESSTOKEN:   %@",accessToken);
    [webDataScan scanUpToString:@"AuthenticationToken:'" intoString:nil];
    [webDataScan scanString:@"AuthenticationToken:'" intoString:nil];
    [webDataScan scanUpToString:@"'" intoString:&AuthenticationToken];
    NSLog(@"AUTHENTICATIONTOKEN:   %@",AuthenticationToken);
    [webDataScan scanUpToString:@"expires_in:" intoString:nil];
    [webDataScan scanString:@"expires_in:" intoString:nil];
    [webDataScan scanUpToString:@"}" intoString:&expiresIn];
    NSLog(@"%@",expiresIn);
    if (accessToken != nil || AuthenticationToken != nil || expiresIn != nil) {
        
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://settings.svc.halowaypoint.com/RegisterClientService.svc/spartantoken/wlid"]];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"v1=%@",accessToken] forHTTPHeaderField:@"X-343-Authorization-WLID"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        [connection start];
    } else {
        //NSLog(@"ERROR ACCESSTOKEN NOT FOUND");
        
    }
}






-(NSDictionary *)GetUserAchievements:(NSString *)gamertag{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://haloplayer.svc.halowaypoint.com/HaloPlayer/GetUserAchievements?titleId=1297287449"]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
    
}
-(NSDictionary *)GetOtherUserAchievements:(NSString *)gamertag{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://haloplayer.svc.halowaypoint.com/HaloPlayer/GetOtherUserAchievements?requesteeGamertag={requesteeGamertag}&titleId=1297287449"]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetPlaylists:(NSString *)gamertag{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://presence.svc.halowaypoint.com/en-us/h4/playlists"]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetGlobalChallenges:(NSString *)gamertag{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/h4/challenges"]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetPlayerChallenges:(NSString *)gamertag{
    
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/challenges",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetGameMetadata:(NSString *)gamertag{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/h4/metadata"]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetPlayerCard:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/playercard",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetMultiplePlayerCards:(NSString *)gamertag{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/h4/playercards?gamertags={gamertags}"]];
    
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetServiceRecord:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/servicerecord",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    
    return dictonary;
}
-(NSDictionary *)GetGameHistory:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/matches",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetGameDetails:(NSString *)gameID{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/h4/matches/%@",gameID]];
    
    //http://services.xboxlive.com/en-us/LiveStats/CurrentGame
    //https://stats.svc.halowaypoint.com/en-us/h4/matches/%@",gameID
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetCommendations:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/commendations",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetRanks:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/ranks",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetCampaignDetails:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/servicerecord/campaign",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetSpartanOpsDetails:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/servicerecord/spartanops",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetWarGameDetails:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/servicerecord/wargames",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}
-(NSDictionary *)GetCustomGameDetails:(NSString *)gamertag{
    NSString *gamertagWeb = [gamertag stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://stats.svc.halowaypoint.com/en-us/players/%@/h4/servicerecord/custom",gamertagWeb]];
    __block NSDictionary *dictonary;
    
    if (_hasSpartanToken == YES) {
        
        
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"GET"];
        [request setValue:[NSString stringWithFormat:@"%@",_spartanToken] forHTTPHeaderField:@"X-343-Authorization-Spartan"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        
        [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response2,
                                                                                          NSData *data2,
                                                                                          NSError *error2)
         {
             
             if ([data2 length] >0 && error2 == nil)
             {
                 
                 NSError *error;
                 dictonary = [NSJSONSerialization JSONObjectWithData:data2 options:NSASCIIStringEncoding error:&error];
                 
                 
             }
             else if ([data2 length] == 0 && error2 == nil)
             {
                 //NSLog(@"Nothing was downloaded.");
             }
             else if (error2 != nil){
                 //NSLog(@"Error = %@", error2.localizedDescription);
             }
             
         }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Authorization failed the servers might be down" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        });
        
        return nil;
    }
    while (dictonary == nil)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    return dictonary;
}




-(NSMutableArray *)dellegates {
    if (!_dellegates) {
        _dellegates = [[NSMutableArray alloc] init];
    }
    return _dellegates;
}

-(void)addDelegate:(id<H4APIStatRetreivalDelegate>)delegate {
    if (delegate != nil) {
        [self.dellegates addObject:delegate];
    }
}


-(void)removeDelegate:(id<H4APIStatRetreivalDelegate>)delegate{
    if ([self.dellegates containsObject:delegate]) {
        [self.dellegates removeObject:delegate];
    }
    
}




-(void)didGetAutho{
    
    for (id<H4APIStatRetreivalDelegate> delegate in self.dellegates) {
        if ([delegate respondsToSelector:@selector(didGetAuthoDel)]) {
            [delegate didGetAuthoDel];
        }
    }
    
}
-(void)FailedAutho{
    for (id<H4APIStatRetreivalDelegate> delegate in self.dellegates) {
        if ([delegate respondsToSelector:@selector(FailedAuthoDel)]) {
            [delegate FailedAuthoDel];
        }
    }
    
}
-(void)receivingAuth{
    for (id<H4APIStatRetreivalDelegate> delegate in self.dellegates) {
        if ([delegate respondsToSelector:@selector(receivingAuthDel)]) {
            [delegate receivingAuthDel];
        }
    }
    
}

@end
