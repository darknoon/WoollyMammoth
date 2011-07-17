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
@synthesize queue;

- (PhotoTweet *)currentTweet {
    return _downloadedPhotoTweets.count ? [_downloadedPhotoTweets objectAtIndex:0] : nil;
}
                                           
- (void)advanceToNextTweet {
    if (_downloadedPhotoTweets.count > 1) {
        PhotoTweet * last = [_downloadedPhotoTweets lastObject];
        [_downloadedPhotoTweets removeObject:last];
        [_downloadedPhotoTweets insertObject:last atIndex:0];
    }
}

- (void)photoTweetGotImage:(PhotoTweet *)photoTweet {
    [_downloadedPhotoTweets insertObject:photoTweet atIndex:0];
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
    NSMutableString *s = [NSMutableString stringWithString:@"http://freezing-flower-668.herokuapp.com/tweets.json?tag=iosdevcamp"];
    
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

+ (TweetServerCommunicator *)commmunicator {
    static TweetServerCommunicator *_myOneAndOnly;
    if(!_myOneAndOnly) _myOneAndOnly = [[self alloc] init];
    return _myOneAndOnly;
}


@end
