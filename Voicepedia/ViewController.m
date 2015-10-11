//
//  ViewController.m
//  Voice Web Browser
//
//  Created by Michael Royzen on 10/9/15.
//  Copyright © 2015 Michael Royzen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSMutableData *webData;
    NSURLConnection *connection1;
    NSString *recognizedVoice;
    NSString *recognizedVoice2;
    int speakIndex;
    NSString *articleTitleString;
    NSString *idString;
    NSString *extract;
    AVSpeechSynthesizer *readingSynthesizer;
    int shakeIndex;
}

@end

const unsigned char SpeechKitApplicationKey[] = {0xda, 0xdb, 0x5a, 0xa1, 0x09, 0x50, 0x7f, 0x1c, 0xfb, 0x52, 0x79, 0xb6, 0x1e, 0x7e, 0x1c, 0x45, 0xdc, 0xb5, 0x59, 0x11, 0xfd, 0xd2, 0x51, 0x58, 0xf5, 0xa7, 0x4c, 0x13, 0x29, 0xa2, 0xbc, 0x03, 0x7e, 0x16, 0xa4, 0x87, 0x67, 0x23, 0xa3, 0x62, 0x75, 0x1c, 0x18, 0x94, 0x9a, 0x34, 0xd9, 0x77, 0xe9, 0x33, 0x88, 0xe6, 0x05, 0xd9, 0x3f, 0xfa, 0x80, 0x8b, 0x0d, 0xa9, 0x2d, 0xc9, 0xac, 0xab};

@implementation ViewController
@synthesize logoLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GradientView *gradientView = [[GradientView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:gradientView];
    [self.view sendSubviewToBack:gradientView];
    
    [SpeechKit setupWithID:@"NMDPTRIAL_mlabtechnologies20150120004933" host:@"sslsandbox.nmdp.nuancemobility.net" port:443 useSSL:YES delegate:self];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
    [speechSynthesizer setDelegate:self];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"Welcome to Voicepedia.  Please speak your search term after the vibration."];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
    speakIndex = 1;
    shakeIndex = 0;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (speakIndex == 1) {
        SKEndOfSpeechDetection detectionType;
        NSString* recoType;
        recoType = SKDictationRecognizerType;
        detectionType = SKLongEndOfSpeechDetection;
        
        voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        [logoLabel setText:@"Listening"];
    }
    else if (speakIndex == 2) {
        SKEndOfSpeechDetection detectionType;
        NSString* recoType;
        recoType = SKDictationRecognizerType;
        detectionType = SKLongEndOfSpeechDetection;
        
        voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                               detection:detectionType
                                                language:@"en_US"
                                                delegate:self];
        
        [logoLabel setText:@"Listening"];
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    else if (speakIndex == 3) {
        /*
        recognizedVoice = [recognizedVoice stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=%@", recognizedVoice]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"%@", url);
        connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection){
            webData = [[NSMutableData alloc]init];
        }
         */
    }
    else if (speakIndex == 4) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&titles=%@", articleTitleString]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"%@", url);
        connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection1){
            webData = [[NSMutableData alloc]init];
        }
    }
    else if (speakIndex == 5) {
        speakIndex = 6;
        readingSynthesizer = [[AVSpeechSynthesizer alloc] init];
        [readingSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:[@"We will begin reading the article intro now.  Please shake the device to stop reading.              " stringByAppendingString:extract]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
            [utterance setRate:0.5];
        }
        [readingSynthesizer speakUtterance:utterance];
    }
    else if (speakIndex == 6) {
        readingSynthesizer = [[AVSpeechSynthesizer alloc] init];
        [readingSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"We have finished reading your article.  If you want to read another article, please shake the device."];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
            [utterance setRate:0.5];
        }
        [readingSynthesizer speakUtterance:utterance];
        speakIndex++;
    }
}

- (void)restartSpeech {
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
    [speechSynthesizer setDelegate:self];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"Paused reading.  If you want to stop, say 'stop' after the vibration.  If you want to resume, shake the device again."];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
}

- (void)restart {
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
    [speechSynthesizer setDelegate:self];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:@"Please speak your new search term after the vibration."];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
    speakIndex = 1;
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        if (speakIndex == 6) {
            [readingSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            NSTimer *timer;
            timer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(restartSpeech) userInfo:nil repeats:NO];
            shakeIndex++;
        }
        if (shakeIndex == 1) {
            [readingSynthesizer continueSpeaking];
            shakeIndex--;
        }
        if (speakIndex == 7) {
            NSTimer *timer;
            timer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(restart) userInfo:nil repeats:NO];
        }
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [webData setLength:0];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [webData appendData:data];
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
   //UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil,nil];
    //[alertView show];
    
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:error.localizedDescription];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (speakIndex == 3) {
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSArray *arrayOfSearch = [query objectForKey:@"search"];
        NSDictionary *searchDictionary = [arrayOfSearch objectAtIndex:0];
        articleTitleString = [searchDictionary objectForKey:@"title"];
        NSLog(@"%@", articleTitleString);
        articleTitleString = [articleTitleString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        articleTitleString = [articleTitleString stringByReplacingOccurrencesOfString:@"é" withString:@"%E9"];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?action=query&titles=%@&indexpageids=&format=json", articleTitleString]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"URL 1 %@", url);
        connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection1){
            webData = [[NSMutableData alloc]init];
        }
        speakIndex++;
    }
    else if (speakIndex == 4) {
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSArray *pageids = [query objectForKey:@"pageids"];
        idString= [NSString stringWithFormat:@"%@", [pageids firstObject]];
        speakIndex++;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&titles=%@", articleTitleString]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        NSLog(@"URL 2 %@", url);
        connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        if(connection1){
            webData = [[NSMutableData alloc]init];
        }
    }
    else if (speakIndex == 5) {
        NSDictionary *allDataDictionary = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
        NSDictionary *query = [allDataDictionary objectForKey:@"query"];
        NSDictionary *pages = [query objectForKey:@"pages"];
        NSDictionary *pageid = [pages objectForKey:idString];
        extract = [pageid objectForKey:@"extract"];
        NSLog(@"URL 3 %@", extract);
    }
}


- (void)recognizerDidBeginRecording:(SKRecognizer *)recognizer {
    NSLog(@"Recording started");
}

- (void)recognizerDidFinishRecording:(SKRecognizer *)recognizer {
    NSLog(@"Recording finished");
}

- (void)startListening {
    SKEndOfSpeechDetection detectionType;
    NSString* recoType;
    recoType = SKDictationRecognizerType;
    detectionType = SKLongEndOfSpeechDetection;
    
    voiceSearch = [[SKRecognizer alloc] initWithType:recoType
                                           detection:detectionType
                                            language:@"en_US"
                                            delegate:self];
    
    [logoLabel setText:@"Listening"];
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results {
    NSLog(@"Got results");
    NSLog(@"Session ID: [%@].", [SpeechKit sessionID]);
    
    NSLog(@"%@", [results firstResult]);
    
    if ([results firstResult] == nil) {
        NSLog(@"Fired %@", [results firstResult]);
        AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
        [speechSynthesizer setDelegate:self];
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"We're sorry, we didn't catch what you said.  Please try again after the vibration."]];
        if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
            [utterance setRate:0.1];
        } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
            [utterance setRate:0.5];
        }
        [speechSynthesizer speakUtterance:utterance];
    }
    
    [logoLabel setText:@"Voicepedia"];
    
    if ([results firstResult] == nil) {
        
    }
    else {
        if (speakIndex == 1) {
            recognizedVoice = [results firstResult];
            NSLog(@"%@", recognizedVoice);
            speakIndex++;
            AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
            [speechSynthesizer setDelegate:self];
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"Do you want to search for %@", recognizedVoice]];
            if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                [utterance setRate:0.1];
            } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
                [utterance setRate:0.5];
            }
            [speechSynthesizer speakUtterance:utterance];
        }
        else if (speakIndex == 2) {
            recognizedVoice2 = [results firstResult];
            speakIndex ++;
            NSLog(@"%@", recognizedVoice2);
            if ([recognizedVoice2 containsString:@"Yes"] || [recognizedVoice2 containsString:@"yes"]) {
                AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc]init];
                [speechSynthesizer setDelegate:self];
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc]initWithString:[NSString stringWithFormat:@"Ok, we are searching for %@", recognizedVoice]];
                [self searchWikipedia];
                if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
                    [utterance setRate:0.1];
                } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
                    [utterance setRate:0.5];
                }
                [speechSynthesizer speakUtterance:utterance];
            } else if ([recognizedVoice2 containsString:@"No"] || [recognizedVoice2 containsString:@"no"]) {
                NSLog(@"The user said no");
                speakIndex = 1;
                AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
                [speechSynthesizer setDelegate:self];
                AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Ok, we won't search for that.  Please speak your new search term after the vibration."];
                if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
                    [utterance setRate:0.1];
                } else if ([[UIDevice currentDevice] systemVersion].floatValue >= 9.0) {
                    [utterance setRate:0.5];
                }
                [speechSynthesizer speakUtterance:utterance];
            }
        }
    }
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion {
    AVSpeechSynthesizer *speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:error.localizedDescription];
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0 && [[UIDevice currentDevice] systemVersion].floatValue < 9.0) {
        [utterance setRate:0.1];
    } else if ([[UIDevice currentDevice] systemVersion].floatValue == 9.0) {
        [utterance setRate:0.5];
    }
    [speechSynthesizer speakUtterance:utterance];
}

- (void)searchWikipedia {
    recognizedVoice = [recognizedVoice stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://en.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=%@", recognizedVoice]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSLog(@"URL 4%@", url);
    connection1 = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    if(connection1){
        webData = [[NSMutableData alloc]init];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
