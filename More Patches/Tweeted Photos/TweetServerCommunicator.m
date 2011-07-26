//
//  TweetServerCommunicator.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "TweetServerCommunicator.h"
#import "PhotoTweet.h"
#import "ASIHTTPRequest.h"
#import "JSONRepresentation.h"
#import "CJSONDeserializer.h"

@implementation TweetServerCommunicator
@synthesize queue, searchToken;

- (PhotoTweet *)currentTweet {
    if (currentTweetIndex > _downloadedPhotoTweets.count - 1) currentTweetIndex = 0;

    return _downloadedPhotoTweets.count ? [_downloadedPhotoTweets objectAtIndex:currentTweetIndex] : nil;
}
                                           
- (void)advanceToNextTweet {
    currentTweetIndex++;
//    NSLog(@"%d is new tweet index of %d",currentTweetIndex - 1, _downloadedPhotoTweets.count);
    
    if (currentTweetIndex > _downloadedPhotoTweets.count - 1) currentTweetIndex = 0;
//    if (_downloadedPhotoTweets.count > 1) {
//        PhotoTweet * last = [_downloadedPhotoTweets lastObject];
//        [_downloadedPhotoTweets removeObject:last];
//        [_downloadedPhotoTweets insertObject:last atIndex:0];
//    }
}

- (void)photoTweetGotImage:(PhotoTweet *)photoTweet {
    [_downloadedPhotoTweets addObject:photoTweet];
//    NSLog(@"got image: @%", [photoTweet.tweet valueForKey:@"image_url"]);
}

- (void)photoTweetFailedToGetImage:(PhotoTweet *)photoTweet {
    [_allPhotoTweets removeObject:photoTweet];
}

- (IBAction)getPhotoIn:(PhotoTweet *)tweet
{
    NSURL *url = [NSURL URLWithString:[tweet photoImageMediumURLString]];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:tweet];
    [request setDidFinishSelector:@selector(requestFinished:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [[self queue] addOperation:request]; //queue is an NSOperationQueue
}



- (NSString *)requestString {
    NSMutableString *s = [NSMutableString stringWithString:@"http://eyecode.herokuapp.com/tweets.json"];
// this is the real code - but today, July 23 2011, the above url is returning tweets
    if (self.searchToken.length == 0) self.searchToken = @"photo";
    [s appendFormat:@"?tag=%@",self.searchToken];
    if (_lastIDNumber) {
        [s appendFormat:@"&since_id=%llu",_lastIDNumber];
    }
    return s;
}

- (void)talkToServer:(NSTimer *)t {
    NSURL *url = [NSURL URLWithString:[self requestString]];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    __block TweetServerCommunicator *myself = self;
    [request setCompletionBlock:^{
        NSData *responseData = [request responseData];
        CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
        NSError *error = nil;
        
        NSArray *tweets = [deserializer deserialize:responseData error:&error];
        if (!tweets) {
            NSLog(@"decode err: %@", error);
        } else {
            for (NSMutableDictionary *d in tweets) {
                PhotoTweet *t = [PhotoTweet photoTweetWithDictionary:d];
                if (t){
                    unsigned long long thisOne = t.twitterId;
                    t.communicator = self;
                    if (thisOne > _lastIDNumber) _lastIDNumber = thisOne;
                    [_allPhotoTweets addObject:t];
                    [myself getPhotoIn:t];
                }
            }
        }

    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"err: %@", error);
    }];
    [request startAsynchronous];
}

#define GRAB_MORE_TIME 10.0

- (id)init {
    self = [super init];
    _downloadedPhotoTweets = [[NSMutableArray alloc] init];
    _allPhotoTweets = [[NSMutableArray alloc] init];
    _timer = [[NSTimer scheduledTimerWithTimeInterval:GRAB_MORE_TIME target:self selector:@selector(talkToServer:) userInfo:nil repeats:YES] retain];
    [self performSelector:@selector(talkToServer:) withObject:nil afterDelay:0.0];
    [self setQueue:[[[NSOperationQueue alloc] init] autorelease]];

    return self;
}

- (void)dealloc {
    [self.queue setSuspended:YES];
    self.queue = nil;
    [_downloadedPhotoTweets release];
    [_allPhotoTweets release];
    [_timer invalidate];
    [_timer release];
    [super dealloc];
}

@end
